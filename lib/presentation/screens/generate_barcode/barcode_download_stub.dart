import 'package:flutter/foundation.dart';

Future<bool> downloadBarcodePng({
  required String? base64Png,
  required String filename,
}) async {
  if (kDebugMode) {
    debugPrint('Barcode PNG download is only supported on web in this build.');
  }
  return false;
}

Future<bool> downloadBarcodeSvg({
  required String? svg,
  required String filename,
}) async {
  if (kDebugMode) {
    debugPrint('Barcode SVG download is only supported on web in this build.');
  }
  return false;
}
