import 'package:dio/dio.dart';

import '../../../../core/config/api_config.dart';
import '../../../../core/network/player_dio_client.dart';
import '../models/player_auth_models.dart';

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

  final Dio _client = createPlayerDioClient();

  Future<PlayerAuthProfile> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    final response = await _postJson(
      ApiConfig.registerEndpoint,
      data: {
        'name': name.trim(),
        'email': email.trim().toLowerCase(),
        'phone': phone.trim(),
        'password': password,
      },
    );

    return PlayerAuthProfile.fromJson(_asMap(_unwrap(response.data)));
  }

  Future<PlayerAuthLoginResult> login({
    required String email,
    required String password,
  }) async {
    final response = await _postJson(
      ApiConfig.loginEndpoint,
      data: {
        'email': email.trim().toLowerCase(),
        'password': password,
      },
    );

    final data = _asMap(_unwrap(response.data));
    return PlayerAuthLoginResult(
      accessToken: _requireString(data['accessToken'], 'accessToken'),
      user: PlayerAuthProfile.fromJson(_asMap(data['user'])),
    );
  }

  Future<String> refresh() async {
    final response = await _postJson(ApiConfig.refreshEndpoint);
    final data = _asMap(_unwrap(response.data));
    return _requireString(data['accessToken'], 'accessToken');
  }

  Future<String> logout() async {
    final response = await _postJson(ApiConfig.logoutEndpoint);
    final data = _unwrap(response.data);
    final map =
        data is Map ? data.cast<String, dynamic>() : const <String, dynamic>{};
    final message = map['message'];
    return message is String && message.isNotEmpty
        ? message
        : 'Logged out successfully';
  }

  Future<String> forgotPassword({required String email}) async {
    final response = await _postJson(
      ApiConfig.forgotPasswordEndpoint,
      data: {'email': email.trim().toLowerCase()},
    );

    final data = _asMap(_unwrap(response.data));
    return _requireString(data['message'], 'message');
  }

  Future<String> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    final response = await _postJson(
      ApiConfig.resetPasswordEndpoint,
      data: {
        'token': token.trim(),
        'newPassword': newPassword,
      },
    );

    final data = _asMap(_unwrap(response.data));
    return _requireString(data['message'], 'message');
  }

  Future<String> verifyEmail({required String token}) async {
    final response = await _postJson(
      ApiConfig.verifyEmailEndpoint,
      data: {'token': token.trim()},
    );

    final data = _asMap(_unwrap(response.data));
    return _requireString(data['message'], 'message');
  }

  Future<Response<dynamic>> _postJson(
    String endpoint, {
    Map<String, dynamic>? data,
  }) async {
    try {
      return await _client.post<dynamic>(endpoint, data: data);
    } on DioException catch (error) {
      throw _toAuthException(error);
    }
  }

  dynamic _unwrap(dynamic body) {
    if (body is Map && body.containsKey('data')) {
      return body['data'];
    }
    return body;
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

  AuthException _toAuthException(DioException error) {
    final statusCode = error.response?.statusCode ?? 500;
    final data = _unwrap(error.response?.data);

    if (data is Map) {
      final message = data['message'] ?? data['error'] ?? data['detail'];
      if (message is String && message.isNotEmpty) {
        return AuthException(message: message, statusCode: statusCode);
      }

      final validation = data['message'];
      if (validation is List && validation.isNotEmpty) {
        final combined = validation.whereType<String>().join('\n');
        if (combined.isNotEmpty) {
          return AuthException(message: combined, statusCode: statusCode);
        }
      }
    } else if (data is String && data.isNotEmpty) {
      return AuthException(message: data, statusCode: statusCode);
    }

    if (error.message != null && error.message!.isNotEmpty) {
      return AuthException(message: error.message!, statusCode: statusCode);
    }

    return AuthException(
      message: 'Request failed with status $statusCode',
      statusCode: statusCode,
    );
  }
}
