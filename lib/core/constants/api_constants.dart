class ApiConstants {
  static const String baseUrl =
      'https://lightgoldenrodyellow-dugong-733121.hostingersite.com/api/v1';

  static const String authRegister = '/auth/register';
  static const String authLogin = '/auth/login';
  static const String authForgotPassword = '/auth/forgot-password';
  static const String authResetPassword = '/auth/reset-password';
  static const String authLogout = '/auth/logout';
  static const String authMe = '/auth/me';

  static const String scanBarcode = '/scan';
  static const String scanHistory = '/scan/history';

  static const String barcodes = '/barcodes';
  static const String barcodeCheckDuplicate = '/barcodes/check-duplicate';
  static const String barcodeGenerate = '/barcodes/generate';

  static const String dashboardStats = '/dashboard/stats';
  static const String dashboardRecentBarcodes = '/dashboard/recent-barcodes';
}
