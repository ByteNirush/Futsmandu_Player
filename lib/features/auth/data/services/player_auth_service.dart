import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../../core/config/api_config.dart';
import '../../../../core/services/player_auth_storage_service.dart';
import '../../../../core/services/player_http_client.dart';

class AuthException implements Exception {
  const AuthException({required this.message, required this.statusCode});

  final String message;
  final int statusCode;

  @override
  String toString() => 'AuthException($statusCode): $message';
}

class PlayerAuthService {
  PlayerAuthService._internal();

  static final PlayerAuthService instance = PlayerAuthService._internal();

  final http.Client _client = createPlayerHttpClient();
  final PlayerAuthStorageService _storage = PlayerAuthStorageService.instance;

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    final response = await _postJson(
      ApiConfig.registerEndpoint,
      body: {
        'name': name.trim(),
        'email': email.trim(),
        'phone': phone.trim(),
        'password': password,
      },
    );

    final decoded = _decodeBody(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _toAuthException(decoded, response.statusCode);
    }

    return _asMap(decoded);
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await _postJson(
      ApiConfig.loginEndpoint,
      body: {
        'email': email.trim(),
        'password': password,
      },
    );

    final decoded = _decodeBody(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _toAuthException(decoded, response.statusCode);
    }

    final data = _asMap(decoded);
    final accessToken = _requireString(data['accessToken'], 'accessToken');
    final user = _asMap(data['user']);

    await _storage.saveAccessToken(accessToken);
    await _storage.saveUser(user);
    await _persistRefreshTokenFromResponse(response, data);

    return data;
  }

  Future<String> refresh() async {
    final response = await _postJson(
      ApiConfig.refreshEndpoint,
      includeRefreshCookie: true,
    );

    final decoded = _decodeBody(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _toAuthException(decoded, response.statusCode);
    }

    final data = _asMap(decoded);
    final accessToken = _requireString(data['accessToken'], 'accessToken');
    await _storage.saveAccessToken(accessToken);
    await _persistRefreshTokenFromResponse(response, data);
    return accessToken;
  }

  Future<void> logout() async {
    final response = await _postJson(
      ApiConfig.logoutEndpoint,
      includeRefreshCookie: true,
    );

    final decoded = _decodeBody(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _toAuthException(decoded, response.statusCode);
    }

    await _storage.clearSession();
  }

  Future<String> forgotPassword({required String email}) async {
    final response = await _postJson(
      ApiConfig.forgotPasswordEndpoint,
      body: {'email': email.trim()},
    );

    final decoded = _decodeBody(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _toAuthException(decoded, response.statusCode);
    }

    final data = _asMap(decoded);
    return _requireString(data['message'], 'message');
  }

  Future<String> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    final response = await _postJson(
      ApiConfig.resetPasswordEndpoint,
      body: {
        'token': token.trim(),
        'newPassword': newPassword,
      },
    );

    final decoded = _decodeBody(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _toAuthException(decoded, response.statusCode);
    }

    final data = _asMap(decoded);
    return _requireString(data['message'], 'message');
  }

  Future<String> verifyEmail({required String token}) async {
    final response = await _postJson(
      ApiConfig.verifyEmailEndpoint,
      body: {'token': token.trim()},
    );

    final decoded = _decodeBody(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _toAuthException(decoded, response.statusCode);
    }

    final data = _asMap(decoded);
    return _requireString(data['message'], 'message');
  }

  Future<http.Response> _postJson(
    String endpoint, {
    Map<String, dynamic>? body,
    bool includeRefreshCookie = false,
  }) async {
    final headers = await _buildHeaders(includeRefreshCookie: includeRefreshCookie);

    if (kDebugMode) {
      print('POST ${ApiConfig.baseUrl}$endpoint');
    }

    return _client.post(
      Uri.parse('${ApiConfig.baseUrl}$endpoint'),
      headers: headers,
      body: body == null ? null : jsonEncode(body),
    );
  }

  Future<Map<String, String>> _buildHeaders({
    bool includeRefreshCookie = false,
  }) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (includeRefreshCookie && !kIsWeb) {
      final refreshToken = await _storage.getRefreshToken();
      if (refreshToken != null && refreshToken.isNotEmpty) {
        headers['Cookie'] = 'refreshToken=$refreshToken';
      }
    }

    return headers;
  }

  Future<void> _persistRefreshTokenFromResponse(
    http.Response response,
    dynamic responseData,
  ) async {
    if (kIsWeb) return;

    final header = response.headers['set-cookie'];
    if (header != null && header.contains('refreshToken=')) {
      final token = _extractRefreshToken(header);
      if (token != null && token.isNotEmpty) {
        await _storage.saveRefreshToken(token);
      }
      return;
    }

    if (responseData is Map && responseData['refreshToken'] is String) {
      final token = responseData['refreshToken'] as String;
      if (token.isNotEmpty) {
        await _storage.saveRefreshToken(token);
      }
    }
  }

  String? _extractRefreshToken(String setCookieHeader) {
    final match = RegExp(r'refreshToken=([^;]+)').firstMatch(setCookieHeader);
    if (match == null) return null;
    return Uri.decodeComponent(match.group(1) ?? '');
  }

  dynamic _decodeBody(String body) {
    final trimmed = body.trim();
    if (trimmed.isEmpty) return null;

    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is Map && decoded.containsKey('data')) {
        return decoded['data'];
      }
      return decoded;
    } catch (_) {
      return trimmed;
    }
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return value.cast<String, dynamic>();
    throw const AuthException(
      message: 'Unexpected server response',
      statusCode: 500,
    );
  }

  String _requireString(dynamic value, String fieldName) {
    if (value is String && value.isNotEmpty) return value;
    throw AuthException(
      message: 'Server did not return $fieldName',
      statusCode: 500,
    );
  }

  AuthException _toAuthException(dynamic decoded, int statusCode) {
    if (decoded is Map) {
      final message = decoded['message'] ?? decoded['error'] ?? decoded['detail'];
      if (message is String && message.isNotEmpty) {
        return AuthException(message: message, statusCode: statusCode);
      }
    } else if (decoded is String && decoded.isNotEmpty) {
      return AuthException(message: decoded, statusCode: statusCode);
    }

    return AuthException(
      message: 'Request failed with status $statusCode',
      statusCode: statusCode,
    );
  }
}