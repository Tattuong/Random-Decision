import 'package:flutter/foundation.dart';

import '../core/constants/api_constants.dart';
import '../core/services/api_client.dart';
import '../core/services/platform_api_service.dart';
import '../core/services/purchase_sync_service.dart';
import '../core/services/storage_service.dart';
import '../models/auth_models.dart';

class AuthProvider extends ChangeNotifier {
  AuthUser? _user;
  bool _busy = false;
  bool _ready = false;

  AuthUser? get user => _user;
  bool get isLoggedIn => _user != null && _user!.id.isNotEmpty;
  bool get isBusy => _busy;
  bool get isReady => _ready;

  Future<void> restore() async {
    ApiClient.instance.onSessionExpired = _onSessionExpired;

    final cached = await StorageService.instance.getData(ApiConstants.userCacheKey);
    if (cached != null) {
      _user = AuthUser.fromJson(cached);
      notifyListeners();
    }

    final hasSession = await ApiClient.instance.hasSession;
    if (!hasSession) {
      if (_user != null) {
        _user = null;
        await StorageService.instance.remove(ApiConstants.userCacheKey);
        notifyListeners();
      }
      _ready = true;
      notifyListeners();
      return;
    }

    try {
      final me = await PlatformApiService.instance.getMe();
      await _setUser(me);
    } on ApiException catch (e) {
      if (e.isUnauthorized) {
        await _clearLocal();
      }
    } catch (e) {
      debugPrint('Auth restore offline: $e');
    }

    _ready = true;
    notifyListeners();
    if (_user != null) {
      await PurchaseSyncService.instance.sync();
    }
  }

  Future<String?> login(String email, String password) async {
    return _authenticate(() => PlatformApiService.instance.login(
          email: email,
          password: password,
        ));
  }

  Future<String?> register(String email, String password, String nickname) async {
    return _authenticate(() => PlatformApiService.instance.register(
          email: email,
          password: password,
          nickname: nickname,
        ));
  }

  Future<void> logout() async {
    _busy = true;
    notifyListeners();
    final refresh = await ApiClient.instance.refreshToken;
    try {
      if (refresh != null && refresh.isNotEmpty) {
        await PlatformApiService.instance.logout(refresh);
      }
    } catch (e) {
      debugPrint('Logout API failed: $e');
    }
    await _clearLocal();
    _busy = false;
    notifyListeners();
  }

  Future<String?> _authenticate(Future<AuthTokens> Function() action) async {
    _busy = true;
    notifyListeners();
    try {
      final tokens = await action();
      await ApiClient.instance.saveTokens(tokens);
      final me = await PlatformApiService.instance.getMe();
      await _setUser(me);
      await PurchaseSyncService.instance.sync();
      return null;
    } on ApiException catch (e) {
      return _mapError(e);
    } catch (e) {
      debugPrint('Auth failed: $e');
      return 'authNetworkError';
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> _setUser(AuthUser user) async {
    _user = user;
    await StorageService.instance.saveData(ApiConstants.userCacheKey, user.toJson());
  }

  Future<void> _clearLocal() async {
    _user = null;
    await ApiClient.instance.clearTokens();
    await StorageService.instance.remove(ApiConstants.userCacheKey);
  }

  void _onSessionExpired() {
    if (_user == null) return;
    _user = null;
    StorageService.instance.remove(ApiConstants.userCacheKey);
    notifyListeners();
  }

  String _mapError(ApiException e) {
    final message = e.message.toLowerCase();
    if (e.message == 'timeout' || e.message == 'network') {
      return 'authNetworkError';
    }
    if (message.contains('already registered')) {
      return 'authEmailTaken';
    }
    if (message.contains('invalid credentials')) {
      return 'authInvalidCredentials';
    }
    if (message.contains('locked')) {
      return 'authAccountLocked';
    }
    if (e.isValidation) {
      return 'authValidationError';
    }
    return 'authUnknownError';
  }
}
