import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'api_models.dart';
import 'api_service.dart';

final apiProvider = ApiProvider();

class ApiProvider extends ChangeNotifier {
  ApiProvider({ApiService? service}) : _service = service ?? ApiService();

  final ApiService _service;

  String? _token;
  ApiUser? _currentUser;
  String? _lastError;

  String? get token => _token;
  ApiUser? get currentUser => _currentUser;
  String? get lastError => _lastError;
  bool get isAuthenticated => _token != null && _token!.isNotEmpty;
  bool get isAdmin => _currentUser?.role == 'admin';

  void _setError(Object error) {
    _lastError = error is ApiException ? error.message : error.toString();
  }

  void _setSession(AuthSession session) {
    _token = session.token;
    _currentUser = session.user;
    _lastError = null;
    notifyListeners();
  }

  void clearSession() {
    _token = null;
    _currentUser = null;
    _lastError = null;
    notifyListeners();
  }

  Future<AuthSession> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      final session = await _service.register(
        name: name,
        email: email,
        password: password,
        passwordConfirmation: passwordConfirmation,
      );
      _setSession(session);
      return session;
    } catch (error) {
      _setError(error);
      rethrow;
    }
  }

  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    try {
      final session = await _service.login(email: email, password: password);
      _setSession(session);
      return session;
    } catch (error) {
      _setError(error);
      rethrow;
    }
  }

  Future<String> forgotPassword({required String email}) async {
    try {
      final message = await _service.forgotPassword(email: email);
      _lastError = null;
      notifyListeners();
      return message;
    } catch (error) {
      _setError(error);
      rethrow;
    }
  }

  Future<String> resetPassword(PasswordResetRequest request) async {
    try {
      final message = await _service.resetPassword(request);
      _lastError = null;
      notifyListeners();
      return message;
    } catch (error) {
      _setError(error);
      rethrow;
    }
  }

  Future<void> logout() async {
    final token = _token;
    if (token != null && token.isNotEmpty) {
      try {
        await _service.logout(token: token);
      } catch (_) {
        // Clear local state even if the server rejects the logout request.
      }
    }
    clearSession();
  }

  Future<ApiUser?> fetchMe() async {
    final token = _token;
    if (token == null || token.isEmpty) {
      return null;
    }

    try {
      final user = await _service.me(token: token);
      _currentUser = user;
      _lastError = null;
      notifyListeners();
      return user;
    } catch (error) {
      _setError(error);
      rethrow;
    }
  }

  Future<ScanResultData> scanBarcode({
    String? uniqueCode,
    List<int>? barcodeImageBytes,
    String? barcodeImageName,
  }) {
    return _service.scanBarcode(
      uniqueCode: uniqueCode,
      barcodeImageBytes: barcodeImageBytes,
      barcodeImageName: barcodeImageName,
    );
  }

  Future<ScanResultData> scanBarcodeByCode(String uniqueCode) {
    return _service.scanBarcodeByCode(uniqueCode: uniqueCode);
  }

  Future<ScanHistoryPage> fetchScanHistory({int perPage = 15, int? page}) {
    final token = _requireToken();
    return _service.fetchScanHistory(
      token: token,
      perPage: perPage,
      page: page,
    );
  }

  Future<BarcodeListResponse> fetchBarcodes({
    int draw = 1,
    int start = 0,
    int length = 10,
    String? search,
    int? orderColumn,
    String? orderDirection,
  }) {
    final token = _requireToken();
    return _service.fetchBarcodes(
      token: token,
      draw: draw,
      start: start,
      length: length,
      search: search,
      orderColumn: orderColumn,
      orderDirection: orderDirection,
    );
  }

  Future<BarcodeDetailItem> fetchBarcodeDetail(String id) {
    final token = _requireToken();
    return _service.fetchBarcodeDetail(token: token, id: id);
  }

  Future<BarcodeDuplicateCheckResult> checkDuplicate(String data) {
    final token = _requireToken();
    return _service.checkDuplicate(token: token, data: data);
  }

  Future<BarcodeGenerateItem> generateBarcode({
    required String barcodeData,
    required String barcodeFormat,
    required String customLabel,
  }) {
    final token = _requireToken();
    return _service.generateBarcode(
      token: token,
      barcodeData: barcodeData,
      barcodeFormat: barcodeFormat,
      customLabel: customLabel,
    );
  }

  Future<BarcodeUpdateItem> updateBarcode({
    required String id,
    required String customLabel,
  }) {
    final token = _requireToken();
    return _service.updateBarcode(
      token: token,
      id: id,
      customLabel: customLabel,
    );
  }

  Future<void> deleteBarcode(String id) {
    final token = _requireToken();
    return _service.deleteBarcode(token: token, id: id);
  }

  Future<DashboardStats> fetchDashboardStats() {
    final token = _requireToken();
    return _service.fetchDashboardStats(token: token);
  }

  Future<RecentBarcodesPage> fetchRecentBarcodes({
    int perPage = 10,
    int? page,
  }) {
    final token = _requireToken();
    return _service.fetchRecentBarcodes(
      token: token,
      perPage: perPage,
      page: page,
    );
  }

  String _requireToken() {
    final token = _token;
    if (token == null || token.isEmpty) {
      throw StateError('Authentication token is not available.');
    }
    return token;
  }
}

class ApiScope extends InheritedNotifier<ApiProvider> {
  const ApiScope({
    super.key,
    required ApiProvider notifier,
    required Widget child,
  }) : super(notifier: notifier, child: child);

  static ApiProvider of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ApiScope>();
    assert(scope != null, 'ApiScope not found in widget tree');
    return scope!.notifier!;
  }
}
