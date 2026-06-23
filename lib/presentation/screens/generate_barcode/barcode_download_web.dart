import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';

Future<bool> downloadBarcodePng({
  required String? base64Png,
  required String filename,
}) async {
  final bytes = _decodeBase64Data(base64Png);
  if (bytes == null) {
    return false;
  }

  final blob = html.Blob([bytes], 'image/png');
  return _triggerDownload(blob, filename);
}

Future<bool> downloadBarcodeSvg({
  required String? svg,
  required String filename,
}) async {
  final text = svg?.trim();
  if (text == null || text.isEmpty) {
    return false;
  }

  final blob = html.Blob([text], 'image/svg+xml;charset=utf-8');
  return _triggerDownload(blob, filename);
}

Uint8List? _decodeBase64Data(String? value) {
  final text = value?.trim();
  if (text == null || text.isEmpty) {
    return null;
  }

  final cleanValue = text.contains(',') ? text.split(',').last : text;
  try {
    return base64Decode(cleanValue);
  } on FormatException {
    return null;
  }
}

bool _triggerDownload(html.Blob blob, String filename) {
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.document.createElement('a') as html.AnchorElement;
  anchor.href = url;
  anchor.download = filename;
  anchor.style.display = 'none';
  html.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  html.Url.revokeObjectUrl(url);
  return true;
}
