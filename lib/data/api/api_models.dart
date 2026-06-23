class ApiEnvelope<T> {
  const ApiEnvelope({
    required this.success,
    required this.message,
    required this.data,
  });

  final bool success;
  final String message;
  final T? data;

  factory ApiEnvelope.fromJson(
    Map<String, dynamic> json, {
    T Function(Object? json)? dataParser,
  }) {
    return ApiEnvelope<T>(
      success: json['success'] == true,
      message: json['message']?.toString() ?? '',
      data: dataParser == null ? json['data'] as T? : dataParser(json['data']),
    );
  }
}

class ApiValidationError {
  const ApiValidationError({required this.field, required this.messages});

  final String field;
  final List<String> messages;
}

class ApiUser {
  const ApiUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.lastLoginAt,
  });

  final int? id;
  final String name;
  final String email;
  final String? role;
  final DateTime? lastLoginAt;

  factory ApiUser.fromJson(Map<String, dynamic> json) {
    return ApiUser(
      id: _asInt(json['id']),
      name: _asString(json['name']),
      email: _asString(json['email']),
      role: json['role']?.toString(),
      lastLoginAt: _asDateTime(json['last_login_at']),
    );
  }
}

class AuthSession {
  const AuthSession({required this.user, required this.token, this.role});

  final ApiUser user;
  final String token;
  final String? role;

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      user: ApiUser.fromJson(_asMap(json['user'])),
      token: _asString(json['token']),
      role: json['role']?.toString(),
    );
  }
}

class PasswordResetRequest {
  const PasswordResetRequest({
    required this.token,
    required this.email,
    required this.password,
    required this.passwordConfirmation,
  });

  final String token;
  final String email;
  final String password;
  final String passwordConfirmation;

  Map<String, dynamic> toJson() => {
    'token': token,
    'email': email,
    'password': password,
    'password_confirmation': passwordConfirmation,
  };
}

class ScanProductSnapshot {
  const ScanProductSnapshot({
    required this.id,
    required this.name,
    required this.sku,
    required this.description,
    required this.price,
    required this.brand,
    required this.category,
    required this.unit,
    required this.stockQuantity,
    required this.raw,
  });

  final int? id;
  final String? name;
  final String? sku;
  final String? description;
  final num? price;
  final String? brand;
  final String? category;
  final String? unit;
  final int? stockQuantity;
  final String? raw;

  factory ScanProductSnapshot.fromJson(Map<String, dynamic> json) {
    return ScanProductSnapshot(
      id: _asInt(json['id']),
      name: json['name']?.toString(),
      sku: json['sku']?.toString(),
      description: json['description']?.toString(),
      price: _asNum(json['price']),
      brand: json['brand']?.toString(),
      category: json['category']?.toString(),
      unit: json['unit']?.toString(),
      stockQuantity: _asInt(json['stock_quantity']),
      raw: json['raw']?.toString(),
    );
  }
}

class ScanResultData {
  const ScanResultData({
    required this.valid,
    required this.uniqueCode,
    required this.barcodeFormat,
    required this.customLabel,
    required this.barcodeImageUrl,
    required this.productName,
    required this.product,
    required this.scannedAt,
  });

  final bool valid;
  final String? uniqueCode;
  final String? barcodeFormat;
  final String? customLabel;
  final String? barcodeImageUrl;
  final String? productName;
  final ScanProductSnapshot? product;
  final DateTime? scannedAt;

  factory ScanResultData.fromJson(Map<String, dynamic> json) {
    return ScanResultData(
      valid: json['valid'] == true,
      uniqueCode: json['unique_code']?.toString(),
      barcodeFormat: json['barcode_format']?.toString(),
      customLabel: json['custom_label']?.toString(),
      barcodeImageUrl: json['barcode_image_url']?.toString(),
      productName: json['product_name']?.toString(),
      product: json['product'] == null
          ? null
          : ScanProductSnapshot.fromJson(_asMap(json['product'])),
      scannedAt: _asDateTime(json['scanned_at']),
    );
  }
}

class ScanHistorySnapshot {
  const ScanHistorySnapshot({
    required this.uniqueCode,
    required this.scanResult,
    required this.createdAt,
    required this.productDataSnapshot,
  });

  final String? uniqueCode;
  final String? scanResult;
  final DateTime? createdAt;
  final ScanProductDataSnapshot? productDataSnapshot;

  factory ScanHistorySnapshot.fromJson(Map<String, dynamic> json) {
    return ScanHistorySnapshot(
      uniqueCode: json['unique_code']?.toString(),
      scanResult: json['scan_result']?.toString(),
      createdAt: _asDateTime(json['created_at']),
      productDataSnapshot: json['product_data_snapshot'] == null
          ? null
          : ScanProductDataSnapshot.fromJson(
              _asMap(json['product_data_snapshot']),
            ),
    );
  }
}

class ScanProductDataSnapshot {
  const ScanProductDataSnapshot({
    required this.uniqueCode,
    required this.barcodeFormat,
    required this.customLabel,
    required this.product,
  });

  final String? uniqueCode;
  final String? barcodeFormat;
  final String? customLabel;
  final ScanProductSnapshot? product;

  factory ScanProductDataSnapshot.fromJson(Map<String, dynamic> json) {
    return ScanProductDataSnapshot(
      uniqueCode: json['unique_code']?.toString(),
      barcodeFormat: json['barcode_format']?.toString(),
      customLabel: json['custom_label']?.toString(),
      product: json['product'] == null
          ? null
          : ScanProductSnapshot.fromJson(_asMap(json['product'])),
    );
  }
}

class ScanHistoryPage {
  const ScanHistoryPage({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  final List<ScanHistorySnapshot> items;
  final int? currentPage;
  final int? lastPage;
  final int? perPage;
  final int? total;

  factory ScanHistoryPage.fromJson(Map<String, dynamic> json) {
    final data = (json['data'] as List<dynamic>? ?? [])
        .map((item) => ScanHistorySnapshot.fromJson(_asMap(item)))
        .toList();
    final pagination = _asMap(json['pagination']);
    return ScanHistoryPage(
      items: data,
      currentPage: _asInt(pagination['current_page']),
      lastPage: _asInt(pagination['last_page']),
      perPage: _asInt(pagination['per_page']),
      total: _asInt(pagination['total']),
    );
  }
}

class BarcodeOwner {
  const BarcodeOwner({
    required this.id,
    required this.name,
    required this.email,
  });

  final int? id;
  final String? name;
  final String? email;

  factory BarcodeOwner.fromJson(Map<String, dynamic> json) {
    return BarcodeOwner(
      id: _asInt(json['id']),
      name: json['name']?.toString(),
      email: json['email']?.toString(),
    );
  }
}

class BarcodeProductSnapshot {
  const BarcodeProductSnapshot({
    required this.id,
    required this.name,
    required this.sku,
    required this.description,
    required this.price,
    required this.brand,
    required this.category,
    required this.unit,
    required this.stockQuantity,
    required this.raw,
  });

  final int? id;
  final String? name;
  final String? sku;
  final String? description;
  final num? price;
  final String? brand;
  final String? category;
  final String? unit;
  final int? stockQuantity;
  final String? raw;

  factory BarcodeProductSnapshot.fromJson(Map<String, dynamic> json) {
    return BarcodeProductSnapshot(
      id: _asInt(json['id']),
      name: json['name']?.toString(),
      sku: json['sku']?.toString(),
      description: json['description']?.toString(),
      price: _asNum(json['price']),
      brand: json['brand']?.toString(),
      category: json['category']?.toString(),
      unit: json['unit']?.toString(),
      stockQuantity: _asInt(json['stock_quantity']),
      raw: json['raw']?.toString(),
    );
  }
}

class BarcodeSummaryItem {
  const BarcodeSummaryItem({
    required this.id,
    required this.rowNumber,
    required this.uniqueCode,
    required this.barcodeFormat,
    required this.customLabel,
    required this.barcodeData,
    required this.productName,
    required this.userName,
    required this.barcodeImageUrl,
    required this.createdAt,
  });

  final int? id;
  final int? rowNumber;
  final String? uniqueCode;
  final String? barcodeFormat;
  final String? customLabel;
  final String? barcodeData;
  final String? productName;
  final String? userName;
  final String? barcodeImageUrl;
  final String? createdAt;

  factory BarcodeSummaryItem.fromJson(Map<String, dynamic> json) {
    return BarcodeSummaryItem(
      id: _asInt(json['id']),
      rowNumber: _asInt(json['row_number']),
      uniqueCode: json['unique_code']?.toString(),
      barcodeFormat: json['barcode_format']?.toString(),
      customLabel: json['custom_label']?.toString(),
      barcodeData: json['barcode_data']?.toString(),
      productName: json['product_name']?.toString(),
      userName: json['user_name']?.toString(),
      barcodeImageUrl: json['barcode_image_url']?.toString(),
      createdAt: json['created_at']?.toString(),
    );
  }
}

class BarcodeListResponse {
  const BarcodeListResponse({
    required this.draw,
    required this.recordsTotal,
    required this.recordsFiltered,
    required this.items,
  });

  final int? draw;
  final int? recordsTotal;
  final int? recordsFiltered;
  final List<BarcodeSummaryItem> items;

  factory BarcodeListResponse.fromJson(Map<String, dynamic> json) {
    return BarcodeListResponse(
      draw: _asInt(json['draw']),
      recordsTotal: _asInt(json['recordsTotal']),
      recordsFiltered: _asInt(json['recordsFiltered']),
      items: (json['data'] as List<dynamic>? ?? [])
          .map((item) => BarcodeSummaryItem.fromJson(_asMap(item)))
          .toList(),
    );
  }
}

class BarcodeDetailItem {
  const BarcodeDetailItem({
    required this.id,
    required this.uniqueCode,
    required this.barcodeFormat,
    required this.barcodeData,
    required this.customLabel,
    required this.barcodeImageUrl,
    required this.barcodeImagePath,
    required this.barcodeSvg,
    required this.isActive,
    required this.product,
    required this.user,
    required this.createdAt,
    required this.updatedAt,
    required this.scanCount,
    required this.lastScannedAt,
  });

  final int? id;
  final String? uniqueCode;
  final String? barcodeFormat;
  final String? barcodeData;
  final String? customLabel;
  final String? barcodeImageUrl;
  final String? barcodeImagePath;
  final String? barcodeSvg;
  final bool? isActive;
  final BarcodeProductSnapshot? product;
  final BarcodeOwner? user;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int? scanCount;
  final DateTime? lastScannedAt;

  factory BarcodeDetailItem.fromJson(Map<String, dynamic> json) {
    return BarcodeDetailItem(
      id: _asInt(json['id']),
      uniqueCode: json['unique_code']?.toString(),
      barcodeFormat: json['barcode_format']?.toString(),
      barcodeData: json['barcode_data']?.toString(),
      customLabel: json['custom_label']?.toString(),
      barcodeImageUrl: json['barcode_image_url']?.toString(),
      barcodeImagePath: json['barcode_image_path']?.toString(),
      barcodeSvg: json['barcode_svg']?.toString(),
      isActive: _asBool(json['is_active']),
      product: json['product'] == null
          ? null
          : BarcodeProductSnapshot.fromJson(_asMap(json['product'])),
      user: json['user'] == null
          ? null
          : BarcodeOwner.fromJson(_asMap(json['user'])),
      createdAt: _asDateTime(json['created_at']),
      updatedAt: _asDateTime(json['updated_at']),
      scanCount: _asInt(json['scan_count']),
      lastScannedAt: _asDateTime(json['last_scanned_at']),
    );
  }
}

class BarcodeGenerateItem {
  const BarcodeGenerateItem({
    required this.uniqueCode,
    required this.barcodeFormat,
    required this.barcodeImageBase64,
    required this.barcodeSvg,
    required this.barcodeImageUrl,
    required this.customLabel,
    required this.createdAt,
  });

  final String? uniqueCode;
  final String? barcodeFormat;
  final String? barcodeImageBase64;
  final String? barcodeSvg;
  final String? barcodeImageUrl;
  final String? customLabel;
  final DateTime? createdAt;

  factory BarcodeGenerateItem.fromJson(Map<String, dynamic> json) {
    return BarcodeGenerateItem(
      uniqueCode: json['unique_code']?.toString(),
      barcodeFormat: json['barcode_format']?.toString(),
      barcodeImageBase64: json['barcode_image_base64']?.toString(),
      barcodeSvg: json['barcode_svg']?.toString(),
      barcodeImageUrl: json['barcode_image_url']?.toString(),
      customLabel: json['custom_label']?.toString(),
      createdAt: _asDateTime(json['created_at']),
    );
  }
}

class BarcodeUpdateItem {
  const BarcodeUpdateItem({
    required this.id,
    required this.uniqueCode,
    required this.barcodeFormat,
    required this.customLabel,
    required this.barcodeData,
    required this.productName,
    required this.userName,
    required this.barcodeImageUrl,
    required this.createdAt,
  });

  final int? id;
  final String? uniqueCode;
  final String? barcodeFormat;
  final String? customLabel;
  final String? barcodeData;
  final String? productName;
  final String? userName;
  final String? barcodeImageUrl;
  final String? createdAt;

  factory BarcodeUpdateItem.fromJson(Map<String, dynamic> json) {
    return BarcodeUpdateItem(
      id: _asInt(json['id']),
      uniqueCode: json['unique_code']?.toString(),
      barcodeFormat: json['barcode_format']?.toString(),
      customLabel: json['custom_label']?.toString(),
      barcodeData: json['barcode_data']?.toString(),
      productName: json['product_name']?.toString(),
      userName: json['user_name']?.toString(),
      barcodeImageUrl: json['barcode_image_url']?.toString(),
      createdAt: json['created_at']?.toString(),
    );
  }
}

class BarcodeDuplicateCheckResult {
  const BarcodeDuplicateCheckResult({
    required this.exists,
    required this.count,
  });

  final bool exists;
  final int count;

  factory BarcodeDuplicateCheckResult.fromJson(Map<String, dynamic> json) {
    return BarcodeDuplicateCheckResult(
      exists: json['exists'] == true,
      count: _asInt(json['count']) ?? 0,
    );
  }
}

class DashboardStats {
  const DashboardStats({
    required this.totalBarcodes,
    required this.scansToday,
    required this.uniqueBarcodeData,
    required this.activeUsers,
  });

  final int totalBarcodes;
  final int scansToday;
  final int uniqueBarcodeData;
  final int activeUsers;

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalBarcodes: _asInt(json['total_barcodes']) ?? 0,
      scansToday: _asInt(json['scans_today']) ?? 0,
      uniqueBarcodeData: _asInt(json['unique_barcode_data']) ?? 0,
      activeUsers: _asInt(json['active_users']) ?? 0,
    );
  }
}

class RecentBarcodeItem {
  const RecentBarcodeItem({
    required this.id,
    required this.uniqueCode,
    required this.barcodeFormat,
    required this.customLabel,
    required this.productName,
    required this.barcodeData,
    required this.createdAt,
    required this.user,
    required this.product,
  });

  final int? id;
  final String? uniqueCode;
  final String? barcodeFormat;
  final String? customLabel;
  final String? productName;
  final String? barcodeData;
  final String? createdAt;
  final BarcodeOwner? user;
  final BarcodeProductSnapshot? product;

  factory RecentBarcodeItem.fromJson(Map<String, dynamic> json) {
    return RecentBarcodeItem(
      id: _asInt(json['id']),
      uniqueCode: json['unique_code']?.toString(),
      barcodeFormat: json['barcode_format']?.toString(),
      customLabel: json['custom_label']?.toString(),
      productName: json['product_name']?.toString(),
      barcodeData: json['barcode_data']?.toString(),
      createdAt: json['created_at']?.toString(),
      user: json['user'] == null
          ? null
          : BarcodeOwner.fromJson(_asMap(json['user'])),
      product: json['product'] == null
          ? null
          : BarcodeProductSnapshot.fromJson(_asMap(json['product'])),
    );
  }
}

class RecentBarcodesPage {
  const RecentBarcodesPage({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  final List<RecentBarcodeItem> items;
  final int? currentPage;
  final int? lastPage;
  final int? perPage;
  final int? total;

  factory RecentBarcodesPage.fromJson(Map<String, dynamic> json) {
    final data = _asMap(json['data']);
    final pagination = _asMap(data['pagination']);
    return RecentBarcodesPage(
      items: (data['data'] as List<dynamic>? ?? [])
          .map((item) => RecentBarcodeItem.fromJson(_asMap(item)))
          .toList(),
      currentPage: _asInt(pagination['current_page']),
      lastPage: _asInt(pagination['last_page']),
      perPage: _asInt(pagination['per_page']),
      total: _asInt(pagination['total']),
    );
  }
}

Map<String, dynamic> _asMap(Object? value) {
  return value is Map<String, dynamic> ? value : <String, dynamic>{};
}

String _asString(Object? value) => value?.toString() ?? '';

int? _asInt(Object? value) {
  if (value is int) return value;
  return int.tryParse(value?.toString() ?? '');
}

num? _asNum(Object? value) {
  if (value is num) return value;
  return num.tryParse(value?.toString() ?? '');
}

bool? _asBool(Object? value) {
  if (value is bool) return value;
  if (value == null) return null;
  final text = value.toString().toLowerCase();
  if (text == 'true' || text == '1') return true;
  if (text == 'false' || text == '0') return false;
  return null;
}

DateTime? _asDateTime(Object? value) {
  final text = value?.toString();
  if (text == null || text.isEmpty) return null;
  return DateTime.tryParse(text);
}
