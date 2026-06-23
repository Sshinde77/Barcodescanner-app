import 'package:flutter/material.dart';

enum BarcodeFormatOption { code128, qr, code39, ean13, upc }

extension BarcodeFormatOptionX on BarcodeFormatOption {
  String get label {
    switch (this) {
      case BarcodeFormatOption.code128:
        return 'Code128';
      case BarcodeFormatOption.qr:
        return 'QR Code';
      case BarcodeFormatOption.code39:
        return 'Code39';
      case BarcodeFormatOption.ean13:
        return 'EAN13';
      case BarcodeFormatOption.upc:
        return 'UPC';
    }
  }

  IconData get icon {
    switch (this) {
      case BarcodeFormatOption.code128:
        return Icons.view_week_rounded;
      case BarcodeFormatOption.qr:
        return Icons.qr_code_2_rounded;
      case BarcodeFormatOption.code39:
        return Icons.view_week_rounded;
      case BarcodeFormatOption.ean13:
        return Icons.tune_rounded;
      case BarcodeFormatOption.upc:
        return Icons.local_offer_rounded;
    }
  }
}

class MockBarcodeItem {
  const MockBarcodeItem({
    required this.apiId,
    required this.id,
    required this.code,
    required this.productName,
    required this.customLabel,
    required this.format,
    required this.createdAt,
    required this.status,
    required this.scannedCount,
  });

  final String? apiId;
  final String id;
  final String code;
  final String productName;
  final String? customLabel;
  final BarcodeFormatOption format;
  final String createdAt;
  final String status;
  final int scannedCount;

  Color get accentColor {
    switch (status) {
      case 'Active':
        return const Color(0xFF22C55E);
      case 'Draft':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF14B8A6);
    }
  }
}

const mockBarcodes = <MockBarcodeItem>[
  MockBarcodeItem(
    apiId: '1',
    id: '001',
    code: 'SBM-2026-001',
    productName: 'Premium Thermal Label Pack',
    customLabel: 'Premium Thermal Label Pack',
    format: BarcodeFormatOption.code128,
    createdAt: '20 Jun 2026',
    status: 'Active',
    scannedCount: 42,
  ),
  MockBarcodeItem(
    apiId: '2',
    id: '002',
    code: '8901234567895',
    productName: 'Stainless Water Bottle',
    customLabel: 'Stainless Water Bottle',
    format: BarcodeFormatOption.ean13,
    createdAt: '18 Jun 2026',
    status: 'Draft',
    scannedCount: 19,
  ),
  MockBarcodeItem(
    apiId: '3',
    id: '003',
    code: 'SBM-QR-PRD-003',
    productName: 'Smart Inventory Tag',
    customLabel: 'Smart Inventory Tag',
    format: BarcodeFormatOption.qr,
    createdAt: '16 Jun 2026',
    status: 'Active',
    scannedCount: 63,
  ),
  MockBarcodeItem(
    apiId: '4',
    id: '004',
    code: '123456789012',
    productName: 'Portable Scanner Dock',
    customLabel: 'Portable Scanner Dock',
    format: BarcodeFormatOption.upc,
    createdAt: '15 Jun 2026',
    status: 'Archived',
    scannedCount: 7,
  ),
];
