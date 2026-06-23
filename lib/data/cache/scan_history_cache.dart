import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../mock/mock_scan_history.dart';

class ScanHistoryCache {
  ScanHistoryCache._();

  static const String _key = 'landing_scan_history_cache';

  static Future<List<MockScanHistoryItem>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) {
      return <MockScanHistoryItem>[];
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return <MockScanHistoryItem>[];
      }

      return decoded
          .whereType<Map>()
          .map(
            (item) => MockScanHistoryItem(
              id: item['id']?.toString() ?? '',
              title: item['title']?.toString() ?? 'Scanned Barcode',
              code: item['code']?.toString() ?? '',
              time: item['time']?.toString() ?? '',
              subtitle: item['subtitle']?.toString() ?? '',
              isValid: item['is_valid'] == null
                  ? null
                  : item['is_valid'].toString() == 'true',
              barcodeFormat: item['barcode_format']?.toString(),
              customLabel: item['custom_label']?.toString(),
              productName: item['product_name']?.toString(),
              barcodeImageUrl: item['barcode_image_url']?.toString(),
              scannedAt: DateTime.tryParse(
                item['scanned_at']?.toString() ?? '',
              ),
              brand: item['brand']?.toString(),
              category: item['category']?.toString(),
              unit: item['unit']?.toString(),
              stockQuantity: int.tryParse(item['stock_quantity']?.toString() ?? ''),
            ),
          )
          .toList();
    } catch (_) {
      return <MockScanHistoryItem>[];
    }
  }

  static Future<void> save(List<MockScanHistoryItem> history) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = history
        .map(
          (item) => {
            'id': item.id,
            'title': item.title,
            'code': item.code,
            'time': item.time,
            'subtitle': item.subtitle,
            'is_valid': item.isValid,
            'barcode_format': item.barcodeFormat,
            'custom_label': item.customLabel,
            'product_name': item.productName,
            'barcode_image_url': item.barcodeImageUrl,
            'scanned_at': item.scannedAt?.toIso8601String(),
            'brand': item.brand,
            'category': item.category,
            'unit': item.unit,
            'stock_quantity': item.stockQuantity,
          },
        )
        .toList();
    await prefs.setString(_key, jsonEncode(payload));
  }

  static Future<List<MockScanHistoryItem>> resetToDefaults() async {
    final prefs = await SharedPreferences.getInstance();
    final history = <MockScanHistoryItem>[];
    await save(history);
    return history;
  }
}
