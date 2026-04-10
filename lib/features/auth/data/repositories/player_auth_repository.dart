import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../../core/services/player_auth_storage_service.dart';
import '../models/player_auth_models.dart';
import '../services/player_auth_service.dart';

class PlayerAuthRepository {
  PlayerAuthRepository({
    PlayerAuthService? remoteDataSource,
    PlayerAuthStorageService? storage,
  })  : _remoteDataSource = remoteDataSource ?? PlayerAuthService.instance,
        _storage = storage ?? PlayerAuthStorageService.instance;

  final PlayerAuthService _remoteDataSource;
  final PlayerAuthStorageService _storage;

  Future<PlayerAuthSession?> restoreSession() async {
    final accessToken = await _storage.getAccessToken();
    final refreshToken = await _storage.getRefreshToken();
    final rawUser = await _storage.getUser();

    final user = rawUser == null
        ? PlayerAuthProfile.empty()
        : PlayerAuthProfile.fromJson(rawUser);

    if (accessToken != null && accessToken.isNotEmpty) {
      if (!_isJwtExpired(accessToken)) {
        return PlayerAuthSession(accessToken: accessToken, user: user);
      }
    }

    final canAttemptRefresh =
        kIsWeb || (refreshToken != null && refreshToken.isNotEmpty);
    if (!canAttemptRefresh) {
      await _storage.clearSession();
      return null;
    }

    try {
      final refreshedAccessToken = await _remoteDataSource.refresh();
      await _storage.saveAccessToken(refreshedAccessToken);
      return PlayerAuthSession(
        accessToken: refreshedAccessToken,
        user: user,
      );
    } catch (_) {
      await _storage.clearSession();
      return null;
    }
  }

  Future<PlayerAuthSession> login({
    required String email,
    required String password,
  }) async {
    final result = await _remoteDataSource.login(
      email: email,
      password: password,
    );

    await _storage.saveAccessAndUser(
      accessToken: result.accessToken,
      user: result.user.toJson(),
    );

    return PlayerAuthSession(
      accessToken: result.accessToken,
      user: result.user,
    );
  }

  Future<PlayerAuthProfile> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) {
    return _remoteDataSource.register(
      name: name,
      email: email,
      phone: phone,
      password: password,
    );
  }

  Future<OtpVerificationResult> verifyOtp({
    required String userId,
    required String otp,
  }) {
    return _remoteDataSource.verifyOtp(userId: userId, otp: otp);
  }

  Future<OtpVerificationResult> resendOtp({required String userId}) {
    return _remoteDataSource.resendOtp(userId: userId);
  }

  Future<PlayerAuthSession?> refreshSession() async {
    try {
      final accessToken = await _remoteDataSource.refresh();
      await _storage.saveAccessToken(accessToken);

      final rawUser = await _storage.getUser();
      final user = rawUser == null
          ? PlayerAuthProfile.empty()
          : PlayerAuthProfile.fromJson(rawUser);

      return PlayerAuthSession(accessToken: accessToken, user: user);
    } catch (_) {
      await _storage.clearSession();
      return null;
    }
  }

  Future<void> logout() async {
    try {
      await _remoteDataSource.logout();
    } catch (_) {
      // Always clear local session even if remote logout fails.
    } finally {
      await _storage.clearSession();
    }
  }

  Future<String> forgotPassword({required String email}) {
    return _remoteDataSource.forgotPassword(email: email);
  }

  Future<String> resetPassword({
    required String token,
    required String newPassword,
  }) {
    return _remoteDataSource.resetPassword(
      token: token,
      newPassword: newPassword,
    );
  }

  Future<String> verifyEmail({required String token}) {
    return _remoteDataSource.verifyEmail(token: token);
  }

  bool _isJwtExpired(String token) {
    try {
      final segments = token.split('.');
      if (segments.length != 3) return true;

      final normalized = base64Url.normalize(segments[1]);
      final payload = utf8.decode(base64Url.decode(normalized));
      final decoded = jsonDecode(payload);
      if (decoded is! Map) return true;

      final exp = decoded['exp'];
      if (exp is! num) return true;

      final expiry = DateTime.fromMillisecondsSinceEpoch(exp.toInt() * 1000);
      return DateTime.now()
          .isAfter(expiry.subtract(const Duration(seconds: 30)));
    } catch (_) {
      return true;
    }
  }
}
