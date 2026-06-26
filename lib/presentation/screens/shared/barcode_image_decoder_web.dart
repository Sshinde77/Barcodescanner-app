import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

Future<String?> decodeBarcodeFromImageBytes(
  Uint8List bytes, {
  String? mimeType,
}) async {
  if (bytes.isEmpty) {
    return null;
  }

  await _ensureZxingLoaded();

  final blob = web.Blob(
    <JSUint8Array>[bytes.toJS].toJS,
    web.BlobPropertyBag(type: mimeType ?? 'image/png'),
  );
  final objectUrl = web.URL.createObjectURL(blob);

  try {
    final reader = ZXingBrowserMultiFormatReader(null, 1000);

    final direct = await _tryDecodeUrl(reader, objectUrl);
    if (direct != null && direct.isNotEmpty) {
      return direct;
    }

    final image = web.HTMLImageElement();
    image.src = objectUrl;
    await image.decode().toDart;

    final width = image.naturalWidth > 0 ? image.naturalWidth : image.width;
    final height = image.naturalHeight > 0 ? image.naturalHeight : image.height;
    if (width <= 0 || height <= 0) {
      return null;
    }

    for (final scale in <int>[2, 3, 4]) {
      final scaledDataUrl = _buildWhiteCanvasDataUrl(
        image: image,
        width: width,
        height: height,
        scale: scale,
      );
      if (scaledDataUrl == null) {
        continue;
      }

      final scaled = await _tryDecodeUrl(reader, scaledDataUrl);
      if (scaled != null && scaled.isNotEmpty) {
        return scaled;
      }
    }
  } catch (_) {
    return null;
  } finally {
    web.URL.revokeObjectURL(objectUrl);
  }

  return null;
}

Future<void> _ensureZxingLoaded() async {
  if (web.document.querySelector('script#$_zxingScriptId') != null) {
    return;
  }

  final completer = Completer<void>();
  final script = web.HTMLScriptElement()
    ..id = _zxingScriptId
    ..src = _zxingScriptUrl
    ..type = 'application/javascript'
    ..async = true
    ..defer = false
    ..crossOrigin = 'anonymous'
    ..onload = ((JSAny _) {
      if (!completer.isCompleted) {
        completer.complete();
      }
    }).toJS
    ..onerror = ((JSAny _) {
      if (!completer.isCompleted) {
        completer.completeError(
          StateError('Failed to load ZXing barcode decoder script.'),
        );
      }
    }).toJS;

  web.document.head?.append(script);
  await completer.future;
}

Future<String?> _tryDecodeUrl(
  ZXingBrowserMultiFormatReader reader,
  String url,
) async {
  try {
    final result = await reader.decodeFromImageUrl(url).toDart;
    final text = result.text;
    return text != null && text.isNotEmpty ? text : null;
  } catch (_) {
    return null;
  }
}

String? _buildWhiteCanvasDataUrl({
  required web.HTMLImageElement image,
  required int width,
  required int height,
  required int scale,
}) {
  final canvas = web.HTMLCanvasElement()
    ..width = width * scale
    ..height = height * scale;

  final context = canvas.getContext('2d');
  if (context == null) {
    return null;
  }

  final canvasContext = context as web.CanvasRenderingContext2D;
  canvasContext.imageSmoothingEnabled = false;
  canvasContext.fillStyle = '#ffffff'.toJS;
  canvasContext.fillRect(0, 0, canvas.width, canvas.height);
  canvasContext.drawImage(image, 0, 0, canvas.width, canvas.height);

  return canvas.toDataURL('image/png');
}

@JS('ZXing.BrowserMultiFormatReader')
extension type ZXingBrowserMultiFormatReader._(JSObject _) implements JSObject {
  external factory ZXingBrowserMultiFormatReader(JSObject? hints, int timeBetweenScansMillis);

  external JSPromise<ZXingResult> decodeFromImageUrl(String url);
}

extension type ZXingResult._(JSObject _) implements JSObject {
  external String? get text;
}

const String _zxingScriptId = 'zxing-browser-multi-format-reader';
const String _zxingScriptUrl = 'https://unpkg.com/@zxing/library@0.21.3';
