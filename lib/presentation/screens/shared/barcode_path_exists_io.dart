import 'dart:io';

bool barcodePathExists(String path) => File(path).existsSync();
