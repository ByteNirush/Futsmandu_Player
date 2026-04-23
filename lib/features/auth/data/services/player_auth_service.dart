import 'package:dio/dio.dart';

import '../../../../core/config/api_config.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/error_handler.dart';
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

  final ApiClient _client = ApiClient.instance;

  Future<Player> register({
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

    return Player.fromJson(_asMap(_unwrap(response.data)));
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

    final authResponse =
        AuthResponse.fromLoginJson(_asMap(_unwrap(response.data)));
    return PlayerAuthLoginResult.fromAuthResponse(authResponse);
  }

  Future<String> refresh() async {
    final response = await _postJson(ApiConfig.refreshEndpoint);
    final authResponse =
        AuthResponse.fromRefreshJson(_asMap(_unwrap(response.data)));
    return authResponse.token.accessToken;
  }

  Future<OtpVerificationResult> verifyOtp({
    required String userId,
    required String otp,
  }) async {
    final response = await _postJson(
      ApiConfig.verifyOtpEndpoint,
      data: {
        'userId': userId.trim(),
        'otp': otp.trim(),
      },
    );

    return OtpVerificationResult.fromJson(_asMap(_unwrap(response.data)));
  }

  Future<OtpVerificationResult> resendOtp({required String userId}) async {
    final response = await _postJson(
      ApiConfig.resendOtpEndpoint,
      data: {'userId': userId.trim()},
    );

    return OtpVerificationResult.fromJson(_asMap(_unwrap(response.data)));
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
      return await _client.post(endpoint, data: data);
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
    return AuthException(
      message: ErrorHandler.messageFor(error),
      statusCode: statusCode,
    );
  }
}
