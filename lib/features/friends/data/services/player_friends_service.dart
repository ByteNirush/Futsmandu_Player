import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/config/api_config.dart';
import '../../../../core/services/player_auth_storage_service.dart';
import '../../../../core/services/player_http_client.dart';

class FriendsApiException implements Exception {
  const FriendsApiException({required this.message, required this.statusCode});

  final String message;
  final int statusCode;

  @override
  String toString() => 'FriendsApiException($statusCode): $message';
}

class PlayerFriendsService {
  PlayerFriendsService._internal();

  static final PlayerFriendsService instance = PlayerFriendsService._internal();

  final http.Client _client = createPlayerHttpClient();
  final PlayerAuthStorageService _authStorage =
      PlayerAuthStorageService.instance;

  Future<List<Map<String, dynamic>>> getFriends() async {
    final response = await _client.get(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.friendsEndpoint}'),
      headers: await _buildHeaders(includeAuthToken: true),
    );

    final decoded = _decodeBody(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _toFriendsApiException(decoded, response.statusCode);
    }

    final records = _asMapList(decoded);
    return records.map(_normalizeFriend).toList(growable: false);
  }

  Future<List<Map<String, dynamic>>> getFriendRequests() async {
    final response = await _client.get(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.friendsEndpoint}/requests'),
      headers: await _buildHeaders(includeAuthToken: true),
    );

    final decoded = _decodeBody(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _toFriendsApiException(decoded, response.statusCode);
    }

    final records = _asMapList(decoded);
    return records.map(_normalizeIncomingRequest).toList(growable: false);
  }

  Future<List<Map<String, dynamic>>> searchPlayers({
    required String query,
    int limit = 10,
  }) async {
    final uri =
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.friendsEndpoint}/search')
            .replace(
      queryParameters: {
        'q': query,
        'limit': '$limit',
      },
    );

    final response = await _client.get(
      uri,
      headers: await _buildHeaders(includeAuthToken: true),
    );

    final decoded = _decodeBody(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _toFriendsApiException(decoded, response.statusCode);
    }

    final records = _asMapList(decoded);
    return records.map(_normalizeSearchPlayer).toList(growable: false);
  }

  Future<Map<String, dynamic>> sendFriendRequest({
    required String recipientId,
  }) async {
    final response = await _client.post(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.friendsEndpoint}/request'),
      headers: await _buildHeaders(
        includeAuthToken: true,
        includeJsonContentType: true,
      ),
      body: jsonEncode({'recipientId': recipientId}),
    );

    final decoded = _decodeBody(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _toFriendsApiException(decoded, response.statusCode);
    }

    return _asMap(decoded);
  }

  Future<Map<String, dynamic>> acceptFriendRequest({
    required String friendshipId,
  }) async {
    final response = await _client.put(
      Uri.parse(
        '${ApiConfig.baseUrl}${ApiConfig.acceptFriendRequestEndpoint(friendshipId)}',
      ),
      headers: await _buildHeaders(includeAuthToken: true),
    );

    final decoded = _decodeBody(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _toFriendsApiException(decoded, response.statusCode);
    }

    return _asMap(decoded);
  }

  Future<Map<String, dynamic>> removeFriendship({
    required String friendshipId,
  }) async {
    final response = await _client.delete(
      Uri.parse(
          '${ApiConfig.baseUrl}${ApiConfig.friendByIdEndpoint(friendshipId)}'),
      headers: await _buildHeaders(includeAuthToken: true),
    );

    final decoded = _decodeBody(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _toFriendsApiException(decoded, response.statusCode);
    }

    return _asMap(decoded);
  }

  Future<Map<String, dynamic>> blockPlayer({
    required String playerId,
  }) async {
    final response = await _client.post(
      Uri.parse(
          '${ApiConfig.baseUrl}${ApiConfig.blockPlayerEndpoint(playerId)}'),
      headers: await _buildHeaders(includeAuthToken: true),
    );

    final decoded = _decodeBody(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _toFriendsApiException(decoded, response.statusCode);
    }

    return _asMap(decoded);
  }

  Future<Map<String, String>> _buildHeaders({
    bool includeAuthToken = false,
    bool includeJsonContentType = false,
  }) async {
    final headers = <String, String>{
      'Accept': 'application/json',
    };

    if (includeJsonContentType) {
      headers['Content-Type'] = 'application/json';
    }

    if (includeAuthToken) {
      final token = await _authStorage.getAccessToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  Map<String, dynamic> _normalizeFriend(Map<String, dynamic> raw) {
    final friend = _asMap(raw['friend']);
    return {
      'id': _string(friend['id']),
      'friendshipId': _string(raw['friendshipId']),
      'name': _string(friend['name']),
      'avatarUrl': _string(friend['profile_image_url']),
      'skillLevel': _skillLabel(friend['skill_level']),
      'eloRating': _toInt(friend['elo_rating']),
      'matchesPlayed': 0,
      'reliabilityScore': 70,
      'since': _string(raw['since']),
    };
  }

  Map<String, dynamic> _normalizeIncomingRequest(Map<String, dynamic> raw) {
    final requester = _asMap(raw['requester']);
    return {
      'id': _string(requester['id']),
      'friendshipId': _string(raw['id']),
      'name': _string(requester['name']),
      'avatarUrl': _string(requester['profile_image_url']),
      'skillLevel': _skillLabel(requester['skill_level']),
      'mutualFriends': 0,
    };
  }

  Map<String, dynamic> _normalizeSearchPlayer(Map<String, dynamic> raw) {
    return {
      'id': _string(raw['id']),
      'name': _string(raw['name']),
      'avatarUrl': _string(raw['profile_image_url']),
      'skillLevel': _skillLabel(raw['skill_level']),
      'eloRating': _toInt(raw['elo_rating']),
      'matchesPlayed': 0,
    };
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

  FriendsApiException _toFriendsApiException(dynamic decoded, int statusCode) {
    if (decoded is Map) {
      final message =
          decoded['message'] ?? decoded['error'] ?? decoded['detail'];
      if (message is String && message.isNotEmpty) {
        return FriendsApiException(message: message, statusCode: statusCode);
      }
    } else if (decoded is String && decoded.isNotEmpty) {
      return FriendsApiException(message: decoded, statusCode: statusCode);
    }

    return FriendsApiException(
      message: 'Request failed with status $statusCode',
      statusCode: statusCode,
    );
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return value.cast<String, dynamic>();
    throw const FriendsApiException(
      message: 'Unexpected server response',
      statusCode: 500,
    );
  }

  List<Map<String, dynamic>> _asMapList(dynamic value) {
    if (value is! List) return const <Map<String, dynamic>>[];
    return value.map(_asMap).toList(growable: false);
  }

  String _string(dynamic value) {
    if (value is String) return value;
    return '';
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  String _skillLabel(dynamic value) {
    final text = _string(value);
    if (text.isEmpty) return 'Intermediate';
    return text[0].toUpperCase() + text.substring(1);
  }
}
