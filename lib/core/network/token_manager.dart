import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenManager {
  TokenManager._internal();

  static final TokenManager _instance = TokenManager._internal();
  factory TokenManager() => _instance;

  static const String _accessTokenKey = 'player_access_token';
  static const String _refreshTokenKey = 'player_refresh_token';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<void> saveAccessToken(String token) {
    return _storage.write(key: _accessTokenKey, value: token);
  }

  Future<String?> getAccessToken() {
    return _storage.read(key: _accessTokenKey);
  }

  Future<void> deleteAccessToken() {
    return _storage.delete(key: _accessTokenKey);
  }

  Future<void> saveRefreshToken(String token) {
    return _storage.write(key: _refreshTokenKey, value: token);
  }

  Future<String?> getRefreshToken() {
    return _storage.read(key: _refreshTokenKey);
  }

  Future<void> deleteRefreshToken() {
    return _storage.delete(key: _refreshTokenKey);
  }

  Future<void> clearAll() async {
    await Future.wait([
      deleteAccessToken(),
      deleteRefreshToken(),
    ]);
  }
}
