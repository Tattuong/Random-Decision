class ApiConstants {
  ApiConstants._();

  static const String baseUrl = 'https://squa-api.blwsmartware.net/api/v1';
  static const String gameCode = 'com.randomdecision.app';
  static const Duration timeout = Duration(seconds: 12);

  static const String accessTokenKey = 'rd_access_token';
  static const String refreshTokenKey = 'rd_refresh_token';
  static const String userCacheKey = 'rd_auth_user';
  static const String pendingVerifyKey = 'rd_pending_purchase_verify';
}
