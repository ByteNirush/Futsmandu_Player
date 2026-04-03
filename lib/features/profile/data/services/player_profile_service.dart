import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../../../../core/config/api_config.dart';
import '../../../../core/services/player_auth_storage_service.dart';
import '../../../../core/services/player_http_client.dart';

class ProfileApiException implements Exception {
  const ProfileApiException({required this.message, required this.statusCode});

  final String message;
  final int statusCode;

  @override
  String toString() => 'ProfileApiException($statusCode): $message';
}

class PlayerProfileService {
  PlayerProfileService._internal();

  static final PlayerProfileService instance = PlayerProfileService._internal();

  final http.Client _client = createPlayerHttpClient();
  final PlayerAuthStorageService _authStorage =
      PlayerAuthStorageService.instance;

  Future<Map<String, dynamic>> getOwnProfile() async {
    final response = await _client.get(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.profileEndpoint}'),
      headers: await _buildHeaders(includeAuthToken: true),
    );

    final decoded = _decodeBody(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _toProfileApiException(decoded, response.statusCode);
    }

    return _asMap(decoded);
  }

  Future<Map<String, dynamic>> updateOwnProfile({
    String? name,
    String? skillLevel,
    List<String>? preferredRoles,
    bool? showMatchHistory,
  }) async {
    final body = <String, dynamic>{
      if (name != null) 'name': name.trim(),
      if (skillLevel != null) 'skill_level': skillLevel,
      if (preferredRoles != null) 'preferred_roles': preferredRoles,
      if (showMatchHistory != null) 'show_match_history': showMatchHistory,
    };

    final response = await _client.put(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.profileEndpoint}'),
      headers: await _buildHeaders(includeAuthToken: true),
      body: jsonEncode(body),
    );

    final decoded = _decodeBody(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _toProfileApiException(decoded, response.statusCode);
    }

    return _asMap(decoded);
  }

  Future<Map<String, dynamic>> getPublicProfile(String userId) async {
    final response = await _client.get(
      Uri.parse(
          '${ApiConfig.baseUrl}${ApiConfig.publicProfileEndpoint(userId)}'),
      headers: await _buildHeaders(),
    );

    final decoded = _decodeBody(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _toProfileApiException(decoded, response.statusCode);
    }

    return _asMap(decoded);
  }

  Future<Map<String, dynamic>> requestAvatarUploadUrl() async {
    final response = await _client.post(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.profileAvatarEndpoint}'),
      headers: await _buildHeaders(includeAuthToken: true),
    );

    final decoded = _decodeBody(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _toProfileApiException(decoded, response.statusCode);
    }

    return _asMap(decoded);
  }

  Future<String> uploadAvatarBytes(Uint8List bytes) async {
    final uploadPayload = await requestAvatarUploadUrl();
    final uploadUrl = _string(uploadPayload['uploadUrl']);
    final cdnUrl = _string(uploadPayload['cdnUrl']);

    if (uploadUrl.isEmpty || cdnUrl.isEmpty) {
      throw const ProfileApiException(
        message: 'Avatar upload response is invalid',
        statusCode: 500,
      );
    }

    final uploadResponse = await _client.put(
      Uri.parse(uploadUrl),
      headers: const <String, String>{
        'Content-Type': 'image/jpeg',
      },
      body: bytes,
    );

    if (uploadResponse.statusCode < 200 || uploadResponse.statusCode >= 300) {
      throw ProfileApiException(
        message: 'Avatar upload failed (${uploadResponse.statusCode})',
        statusCode: uploadResponse.statusCode,
      );
    }

    return cdnUrl;
  }

  Future<Map<String, String>> _buildHeaders({
    bool includeAuthToken = false,
  }) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (includeAuthToken) {
      final token = await _authStorage.getAccessToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
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
    throw const ProfileApiException(
      message: 'Unexpected server response',
      statusCode: 500,
    );
  }

  String _string(dynamic value) {
    if (value is String) return value;
    return '';
  }

  ProfileApiException _toProfileApiException(dynamic decoded, int statusCode) {
    if (decoded is Map) {
      final message =
          decoded['message'] ?? decoded['error'] ?? decoded['detail'];
      if (message is String && message.isNotEmpty) {
        return ProfileApiException(message: message, statusCode: statusCode);
      }
    } else if (decoded is String && decoded.isNotEmpty) {
      return ProfileApiException(message: decoded, statusCode: statusCode);
    }

    return ProfileApiException(
      message: 'Request failed with status $statusCode',
      statusCode: statusCode,
    );
  }
}
