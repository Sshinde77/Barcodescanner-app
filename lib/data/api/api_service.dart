import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/constants/api_constants.dart';
import 'api_models.dart';

class ApiException implements Exception {
  const ApiException(
    this.message, {
    this.statusCode,
    this.validationErrors,
  });

  final String message;
  final int? statusCode;
  final List<ApiValidationError>? validationErrors;

  @override
  String toString() => message;

  factory ApiException.fromResponse(
    int statusCode,
    Map<String, dynamic> json,
  ) {
    final errorsJson = json['errors'];
    final validationErrors = <ApiValidationError>[];
    if (errorsJson is Map) {
      errorsJson.forEach((key, value) {
        final messages = <String>[];
        if (value is List) {
          messages.addAll(value.map((item) => item.toString()));
        } else if (value != null) {
          messages.add(value.toString());
        }
        validationErrors.add(
          ApiValidationError(field: key.toString(), messages: messages),
        );
      });
    }

    return ApiException(
      json['message']?.toString() ??
          'Request failed with status code $statusCode',
      statusCode: statusCode,
      validationErrors: validationErrors.isEmpty ? null : validationErrors,
    );
  }
}

class ApiService {
  ApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Map<String, String> _headers({String? token, bool jsonBody = true}) {
    return <String, String>{
      'Accept': 'application/json',
      if (jsonBody) 'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Uri _uri(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) {
    final normalizedQuery = <String, String>{};
    if (queryParameters != null) {
      queryParameters.forEach((key, value) {
        if (value != null) {
          normalizedQuery[key] = value.toString();
        }
      });
    }

    return Uri.parse('${ApiConstants.baseUrl}$path').replace(
      queryParameters: normalizedQuery.isEmpty ? null : normalizedQuery,
    );
  }

  Future<Map<String, dynamic>> _sendJson(
    String method,
    String path, {
    Map<String, dynamic>? queryParameters,
    Object? body,
    String? token,
  }) async {
    final request = http.Request(
      method,
      _uri(path, queryParameters: queryParameters),
    );
    request.headers.addAll(_headers(token: token, jsonBody: body != null));
    if (body != null) {
      request.body = jsonEncode(body);
    }

    final streamedResponse = await _client.send(request);
    final response = await http.Response.fromStream(streamedResponse);
    final decoded = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }

    throw ApiException.fromResponse(response.statusCode, decoded);
  }

  Future<AuthSession> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    final json = await _sendJson(
      'POST',
      ApiConstants.authRegister,
      body: {
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
      },
    );
    return AuthSession.fromJson(_unwrapData(json));
  }

  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final json = await _sendJson(
      'POST',
      ApiConstants.authLogin,
      body: {'email': email, 'password': password},
    );
    return AuthSession.fromJson(_unwrapData(json));
  }

  Future<String> forgotPassword({required String email}) async {
    final json = await _sendJson(
      'POST',
      ApiConstants.authForgotPassword,
      body: {'email': email},
    );
    return _unwrapMessage(json);
  }

  Future<String> resetPassword(PasswordResetRequest request) async {
    final json = await _sendJson(
      'POST',
      ApiConstants.authResetPassword,
      body: request.toJson(),
    );
    return _unwrapMessage(json);
  }

  Future<String> logout({required String token}) async {
    final json = await _sendJson(
      'POST',
      ApiConstants.authLogout,
      token: token,
      body: const {},
    );
    return _unwrapMessage(json);
  }

  Future<ApiUser> me({required String token}) async {
    final json = await _sendJson('GET', ApiConstants.authMe, token: token);
    final data = _unwrapData(json);
    final userMap = data['user'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(data['user'] as Map)
        : _mapOf(data['user']);
    return ApiUser.fromJson(userMap);
  }

  Future<ScanResultData> scanBarcode({
    required String uniqueCode,
  }) async {
    final json = await _sendJson(
      'POST',
      ApiConstants.scanBarcode,
      body: {'unique_code': uniqueCode},
    );
    return ScanResultData.fromJson(_unwrapData(json));
  }

  Future<ScanResultData> scanBarcodeByCode({
    required String uniqueCode,
  }) async {
    final json = await _sendJson(
      'GET',
      '${ApiConstants.scanBarcode}/$uniqueCode',
    );
    return ScanResultData.fromJson(_unwrapData(json));
  }

  Future<ScanHistoryPage> fetchScanHistory({
    required String token,
    int perPage = 15,
    int? page,
  }) async {
    final json = await _sendJson(
      'GET',
      ApiConstants.scanHistory,
      token: token,
      queryParameters: {
        'per_page': perPage,
        if (page != null) 'page': page,
      },
    );
    return ScanHistoryPage.fromJson(_unwrapData(json));
  }

  Future<BarcodeListResponse> fetchBarcodes({
    required String token,
    int draw = 1,
    int start = 0,
    int length = 10,
    String? search,
    int? orderColumn,
    String? orderDirection,
  }) async {
    final json = await _sendJson(
      'GET',
      ApiConstants.barcodes,
      token: token,
      queryParameters: {
        'draw': draw,
        'start': start,
        'length': length,
        if (search != null && search.isNotEmpty) 'search[value]': search,
        if (orderColumn != null) 'order[0][column]': orderColumn,
        if (orderDirection != null && orderDirection.isNotEmpty)
          'order[0][dir]': orderDirection,
      },
    );
    return BarcodeListResponse.fromJson(json);
  }

  Future<BarcodeDetailItem> fetchBarcodeDetail({
    required String token,
    required String id,
  }) async {
    final json = await _sendJson(
      'GET',
      '${ApiConstants.barcodes}/$id',
      token: token,
    );
    return BarcodeDetailItem.fromJson(_unwrapData(json));
  }

  Future<BarcodeDuplicateCheckResult> checkDuplicate({
    required String token,
    required String data,
  }) async {
    final json = await _sendJson(
      'GET',
      ApiConstants.barcodeCheckDuplicate,
      token: token,
      queryParameters: {'data': data},
    );
    return BarcodeDuplicateCheckResult.fromJson(_unwrapData(json));
  }

  Future<BarcodeGenerateItem> generateBarcode({
    required String token,
    required String barcodeData,
    required String barcodeFormat,
    required String customLabel,
  }) async {
    final json = await _sendJson(
      'POST',
      ApiConstants.barcodeGenerate,
      token: token,
      body: {
        'barcode_data': barcodeData,
        'barcode_format': barcodeFormat,
        'custom_label': customLabel,
      },
    );
    return BarcodeGenerateItem.fromJson(_unwrapData(json));
  }

  Future<BarcodeUpdateItem> updateBarcode({
    required String token,
    required String id,
    required String customLabel,
  }) async {
    final json = await _sendJson(
      'PUT',
      '${ApiConstants.barcodes}/$id',
      token: token,
      body: {'custom_label': customLabel},
    );
    return BarcodeUpdateItem.fromJson(_unwrapData(json));
  }

  Future<void> deleteBarcode({
    required String token,
    required String id,
  }) async {
    await _sendJson(
      'DELETE',
      '${ApiConstants.barcodes}/$id',
      token: token,
      body: const {},
    );
  }

  Future<DashboardStats> fetchDashboardStats({required String token}) async {
    final json = await _sendJson(
      'GET',
      ApiConstants.dashboardStats,
      token: token,
    );
    return DashboardStats.fromJson(_unwrapData(json));
  }

  Future<RecentBarcodesPage> fetchRecentBarcodes({
    required String token,
    int perPage = 10,
    int? page,
  }) async {
    final json = await _sendJson(
      'GET',
      ApiConstants.dashboardRecentBarcodes,
      token: token,
      queryParameters: {
        'per_page': perPage,
        if (page != null) 'page': page,
      },
    );
    return RecentBarcodesPage.fromJson(json);
  }

  Map<String, dynamic> _unwrapData(Map<String, dynamic> json) {
    final data = json['data'];
    return data is Map<String, dynamic> ? data : _mapOf(data);
  }

  String _unwrapMessage(Map<String, dynamic> json) {
    return json['message']?.toString() ?? '';
  }

  Map<String, dynamic> _mapOf(Object? value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return <String, dynamic>{};
  }
}
