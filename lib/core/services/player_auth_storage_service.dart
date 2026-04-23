import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../network/token_manager.dart';

class PlayerAuthStorageService {
  PlayerAuthStorageService._internal();

  static final PlayerAuthStorageService instance =
      PlayerAuthStorageService._internal();

  static const String _userKey = 'player_user';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final TokenManager _tokenManager = TokenManager();

  Future<void> saveAccessToken(String token) async {
    await _tokenManager.saveAccessToken(token);
  }

  Future<String?> getAccessToken() {
    return _tokenManager.getAccessToken();
  }

  Future<void> saveRefreshToken(String token) async {
    await _tokenManager.saveRefreshToken(token);
  }

  Future<String?> getRefreshToken() {
    return _tokenManager.getRefreshToken();
  }

  Future<void> saveUser(Map<String, dynamic> user) async {
    await _storage.write(key: _userKey, value: jsonEncode(user));
  }

  Future<void> saveSession({
    required String accessToken,
    required String refreshToken,
    required Map<String, dynamic> user,
  }) async {
    await saveAccessToken(accessToken);
    await saveRefreshToken(refreshToken);
    await saveUser(user);
  }

  Future<void> saveAccessAndUser({
    required String accessToken,
    required Map<String, dynamic> user,
  }) async {
    await saveAccessToken(accessToken);
    await saveUser(user);
  }

  Future<Map<String, dynamic>?> getUser() async {
    final raw = await _storage.read(key: _userKey);
    if (raw == null || raw.isEmpty) return null;

    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    if (decoded is Map) {
      return decoded.cast<String, dynamic>();
    }
    return null;
  }

  Future<void> clearSession() async {
    await Future.wait([
      _tokenManager.clearAll(),
      _storage.delete(key: _userKey),
    ]);
  }

  Future<bool> hasStoredRefreshToken() async {
    final refreshToken = await getRefreshToken();
    return refreshToken != null && refreshToken.isNotEmpty;
  }
}
