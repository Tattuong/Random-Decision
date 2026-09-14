import '../../models/auth_models.dart';
import '../constants/api_constants.dart';
import 'api_client.dart';

class PlatformApiService {
  static final PlatformApiService instance = PlatformApiService._();
  PlatformApiService._();

  final ApiClient _api = ApiClient.instance;

  Future<AuthTokens> register({
    required String email,
    required String password,
    required String nickname,
  }) async {
    final data = await _api.post('/auth/register', body: {
      'email': email,
      'password': password,
      'nickname': nickname,
    });
    return _tokensFrom(data);
  }

  Future<AuthTokens> login({
    required String email,
    required String password,
  }) async {
    final data = await _api.post('/auth/login', body: {
      'email': email,
      'password': password,
    });
    return _tokensFrom(data);
  }

  Future<void> logout(String refreshToken) async {
    await _api.post(
      '/auth/logout',
      body: {'refreshToken': refreshToken},
      auth: true,
    );
  }

  Future<AuthUser> getMe() async {
    final data = await _api.get('/me', auth: true);
    if (data is! Map<String, dynamic>) {
      throw const ApiException(null, 'parse');
    }
    return AuthUser.fromJson(data);
  }

  Future<void> verifyPurchase(PendingPurchaseVerify purchase) async {
    await _api.post(
      '/purchase/verify',
      auth: true,
      body: {
        'gameCode': ApiConstants.gameCode,
        'productId': purchase.productId,
        'transactionId': purchase.transactionId,
        'platform': purchase.platform,
        if (purchase.receiptData != null && purchase.receiptData!.isNotEmpty)
          'receiptData': purchase.receiptData,
      },
    );
  }

  AuthTokens _tokensFrom(dynamic data) {
    if (data is! Map<String, dynamic>) {
      throw const ApiException(null, 'parse');
    }
    final tokens = AuthTokens.fromJson(data);
    if (!tokens.isValid) {
      throw const ApiException(null, 'parse');
    }
    return tokens;
  }
}
