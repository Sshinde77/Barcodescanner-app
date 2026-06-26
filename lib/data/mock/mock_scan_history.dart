class MockScanHistoryItem {
  const MockScanHistoryItem({
    required this.id,
    required this.title,
    required this.code,
    required this.time,
    required this.subtitle,
    this.isValid,
    this.barcodeFormat,
    this.customLabel,
    this.productName,
    this.barcodeImageUrl,
    this.publicLink,
    this.scannedAt,
    this.brand,
    this.category,
    this.unit,
    this.stockQuantity,
  });

  final String id;
  final String title;
  final String code;
  final String time;
  final String subtitle;
  final bool? isValid;
  final String? barcodeFormat;
  final String? customLabel;
  final String? productName;
  final String? barcodeImageUrl;
  final String? publicLink;
  final DateTime? scannedAt;
  final String? brand;
  final String? category;
  final String? unit;
  final int? stockQuantity;
}

const mockScanHistory = <MockScanHistoryItem>[
  MockScanHistoryItem(
    id: 'h1',
    title: 'Premium Thermal Label Pack',
    code: 'SBM-2026-001',
    time: '2 min ago',
    subtitle: 'Warehouse A · Shelf 03',
  ),
  MockScanHistoryItem(
    id: 'h2',
    title: 'Smart Inventory Tag',
    code: 'SBM-QR-PRD-003',
    time: '9 min ago',
    subtitle: 'Outbound Scan · Verified',
  ),
  MockScanHistoryItem(
    id: 'h3',
    title: 'Stainless Water Bottle',
    code: '8901234567895',
    time: '21 min ago',
    subtitle: 'Retail Shelf · Category B',
  ),
];
