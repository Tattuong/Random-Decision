import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../models/auth_models.dart';
import '../constants/api_constants.dart';
import 'storage_service.dart';

class ApiClient {
  static final ApiClient instance = ApiClient._();
  ApiClient._();

  final http.Client _http = http.Client();
  Future<AuthTokens?>? _refreshing;
  VoidCallback? onSessionExpired;

  Future<String?> get accessToken =>
      StorageService.instance.getString(ApiConstants.accessTokenKey);

  Future<String?> get refreshToken =>
      StorageService.instance.getString(ApiConstants.refreshTokenKey);

  Future<bool> get hasSession async {
    final access = await accessToken;
    final refresh = await refreshToken;
    return (access != null && access.isNotEmpty) || (refresh != null && refresh.isNotEmpty);
  }

  Future<void> saveTokens(AuthTokens tokens) async {
    await StorageService.instance.saveString(ApiConstants.accessTokenKey, tokens.accessToken);
    await StorageService.instance.saveString(ApiConstants.refreshTokenKey, tokens.refreshToken);
  }

  Future<void> clearTokens() async {
    await StorageService.instance.remove(ApiConstants.accessTokenKey);
    await StorageService.instance.remove(ApiConstants.refreshTokenKey);
  }

  Future<dynamic> get(String path, {bool auth = false}) {
    return _request('GET', path, auth: auth);
  }

  Future<dynamic> post(String path, {Map<String, dynamic>? body, bool auth = false}) {
    return _request('POST', path, body: body, auth: auth);
  }

  Future<dynamic> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    bool auth = false,
    bool retried = false,
  }) async {
    final response = await _send(method, path, body: body, auth: auth);

    if (auth && response.statusCode == 401 && !retried) {
      final refreshed = await _refreshAccessToken();
      if (refreshed) {
        return _request(method, path, body: body, auth: auth, retried: true);
      }
      await clearTokens();
      onSessionExpired?.call();
    }

    return _decode(response);
  }

  Future<http.Response> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
    bool auth = false,
  }) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}$path');
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (auth) {
      final token = await accessToken;
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    try {
      switch (method) {
        case 'GET':
          return await _http.get(uri, headers: headers).timeout(ApiConstants.timeout);
        case 'POST':
          return await _http
              .post(uri, headers: headers, body: body == null ? null : jsonEncode(body))
              .timeout(ApiConstants.timeout);
        default:
          throw const ApiException(null, 'Unsupported method');
      }
    } on TimeoutException {
      throw const ApiException(null, 'timeout');
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException(null, 'network');
    }
  }

  Future<bool> _refreshAccessToken() async {
    final existing = _refreshing;
    if (existing != null) {
      final tokens = await existing;
      return tokens != null;
    }

    final future = _doRefresh();
    _refreshing = future;
    try {
      final tokens = await future;
      return tokens != null;
    } finally {
      _refreshing = null;
    }
  }

  Future<AuthTokens?> _doRefresh() async {
    final token = await refreshToken;
    if (token == null || token.isEmpty) return null;

    try {
      final data = await _request(
        'POST',
        '/auth/refresh',
        body: {'refreshToken': token},
      );
      if (data is! Map<String, dynamic>) return null;
      final tokens = AuthTokens.fromJson(data);
      if (!tokens.isValid) return null;
      await saveTokens(tokens);
      return tokens;
    } catch (_) {
      return null;
    }
  }

  dynamic _decode(http.Response response) {
    dynamic json;
    try {
      json = response.body.isEmpty ? null : jsonDecode(response.body);
    } catch (_) {
      throw ApiException(response.statusCode, 'parse');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (json is Map<String, dynamic> && json.containsKey('data')) {
        return json['data'];
      }
      return json;
    }

    throw ApiException(response.statusCode, _errorMessage(json));
  }

  String _errorMessage(dynamic json) {
    if (json is Map<String, dynamic>) {
      final message = json['message'];
      if (message is List) {
        return message.map((e) => e.toString()).join(', ');
      }
      if (message is String && message.isNotEmpty) {
        return message;
      }
    }
    return 'unknown';
  }
}

typedef VoidCallback = void Function();
