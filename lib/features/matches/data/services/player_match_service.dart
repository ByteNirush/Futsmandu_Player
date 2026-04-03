import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

import '../../../../core/config/api_config.dart';
import '../../../../core/services/player_auth_storage_service.dart';
import '../../../../core/services/player_http_client.dart';

class MatchApiException implements Exception {
  const MatchApiException({required this.message, required this.statusCode});

  final String message;
  final int statusCode;

  @override
  String toString() => 'MatchApiException($statusCode): $message';
}

class PlayerMatchService {
  PlayerMatchService._internal();

  static final PlayerMatchService instance = PlayerMatchService._internal();

  final http.Client _client = createPlayerHttpClient();
  final PlayerAuthStorageService _authStorage =
      PlayerAuthStorageService.instance;

  Future<List<Map<String, dynamic>>> getTonightMatches({
    double latitude = 0,
    double longitude = 0,
  }) async {
    final uri =
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.tonightMatchesEndpoint}')
            .replace(queryParameters: {
      'lat': '$latitude',
      'lng': '$longitude',
    });

    final response = await _client.get(
      uri,
      headers: await _buildHeaders(includeAuthToken: true),
    );

    final decoded = _decodeBody(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _toMatchApiException(decoded, response.statusCode);
    }

    final records = _asMapList(_extractDiscoveryList(decoded));
    final currentUserId = await _currentUserId();
    return records
        .map(
          (raw) => _normalizeDiscoveryMatch(
            raw,
            latitude: latitude,
            longitude: longitude,
            currentUserId: currentUserId,
          ),
        )
        .toList(growable: false);
  }

  Future<List<Map<String, dynamic>>> getTomorrowMatches({
    double latitude = 0,
    double longitude = 0,
  }) async {
    final uri =
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.tomorrowMatchesEndpoint}')
            .replace(queryParameters: {
      'lat': '$latitude',
      'lng': '$longitude',
    });

    final response = await _client.get(
      uri,
      headers: await _buildHeaders(includeAuthToken: true),
    );

    final decoded = _decodeBody(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _toMatchApiException(decoded, response.statusCode);
    }

    final records = _asMapList(_extractDiscoveryList(decoded));
    final currentUserId = await _currentUserId();
    return records
        .map(
          (raw) => _normalizeDiscoveryMatch(
            raw,
            latitude: latitude,
            longitude: longitude,
            currentUserId: currentUserId,
          ),
        )
        .toList(growable: false);
  }

  Future<List<Map<String, dynamic>>> getWeekendMatches({
    double latitude = 0,
    double longitude = 0,
  }) async {
    final uri =
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.weekendMatchesEndpoint}')
            .replace(queryParameters: {
      'lat': '$latitude',
      'lng': '$longitude',
    });

    final response = await _client.get(
      uri,
      headers: await _buildHeaders(includeAuthToken: true),
    );

    final decoded = _decodeBody(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _toMatchApiException(decoded, response.statusCode);
    }

    final records = _asMapList(_extractDiscoveryList(decoded));
    final currentUserId = await _currentUserId();
    return records
        .map(
          (raw) => _normalizeDiscoveryMatch(
            raw,
            latitude: latitude,
            longitude: longitude,
            currentUserId: currentUserId,
          ),
        )
        .toList(growable: false);
  }

  Future<List<Map<String, dynamic>>> getOpenMatches({
    String? date,
    String? skill,
    int limit = 20,
    double latitude = 0,
    double longitude = 0,
  }) async {
    final uri =
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.openMatchesEndpoint}')
            .replace(queryParameters: {
      if (date != null && date.isNotEmpty) 'date': date,
      if (skill != null && skill.isNotEmpty) 'skill': skill,
      'limit': '$limit',
      'lat': '$latitude',
      'lng': '$longitude',
    });

    final response = await _client.get(
      uri,
      headers: await _buildHeaders(includeAuthToken: true),
    );

    final decoded = _decodeBody(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _toMatchApiException(decoded, response.statusCode);
    }

    final records = _asMapList(_extractDiscoveryList(decoded));
    final currentUserId = await _currentUserId();
    return records
        .map(
          (raw) => _normalizeDiscoveryMatch(
            raw,
            latitude: latitude,
            longitude: longitude,
            currentUserId: currentUserId,
          ),
        )
        .toList(growable: false);
  }

  Future<Map<String, dynamic>> getMatch(String matchId) async {
    final response = await _client.get(
      Uri.parse(
          '${ApiConfig.baseUrl}${ApiConfig.matchDetailEndpoint(matchId)}'),
      headers: await _buildHeaders(),
    );

    final decoded = _decodeBody(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _toMatchApiException(decoded, response.statusCode);
    }

    final currentUserId = await _currentUserId();
    return _normalizeMatch(_asMap(decoded), currentUserId: currentUserId);
  }

  Future<Map<String, dynamic>> joinMatch({
    required String matchId,
    String? position,
  }) async {
    final response = await _client.post(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.joinMatchEndpoint(matchId)}'),
      headers: await _buildHeaders(includeAuthToken: true),
      body: jsonEncode({
        if (position != null && position.isNotEmpty) 'position': position,
      }),
    );

    final decoded = _decodeBody(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _toMatchApiException(decoded, response.statusCode);
    }

    return _asMap(decoded);
  }

  Future<Map<String, dynamic>> approveMember({
    required String matchId,
    required String userId,
  }) async {
    final response = await _client.put(
      Uri.parse(
          '${ApiConfig.baseUrl}${ApiConfig.approveMatchMemberEndpoint(matchId, userId)}'),
      headers: await _buildHeaders(includeAuthToken: true),
    );

    final decoded = _decodeBody(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _toMatchApiException(decoded, response.statusCode);
    }

    return _asMap(decoded);
  }

  Future<Map<String, dynamic>> rejectMember({
    required String matchId,
    required String userId,
  }) async {
    final response = await _client.put(
      Uri.parse(
          '${ApiConfig.baseUrl}${ApiConfig.rejectMatchMemberEndpoint(matchId, userId)}'),
      headers: await _buildHeaders(includeAuthToken: true),
    );

    final decoded = _decodeBody(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _toMatchApiException(decoded, response.statusCode);
    }

    return _asMap(decoded);
  }

  Future<Map<String, dynamic>> leaveMatch(String matchId) async {
    final response = await _client.delete(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.leaveMatchEndpoint(matchId)}'),
      headers: await _buildHeaders(includeAuthToken: true),
    );

    final decoded = _decodeBody(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _toMatchApiException(decoded, response.statusCode);
    }

    return _asMap(decoded);
  }

  Future<Map<String, dynamic>> updateTeams({
    required String matchId,
    required List<String> teamA,
    required List<String> teamB,
  }) async {
    final response = await _client.put(
      Uri.parse(
          '${ApiConfig.baseUrl}${ApiConfig.updateMatchTeamsEndpoint(matchId)}'),
      headers: await _buildHeaders(includeAuthToken: true),
      body: jsonEncode({
        'A': teamA,
        'B': teamB,
      }),
    );

    final decoded = _decodeBody(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _toMatchApiException(decoded, response.statusCode);
    }

    return _asMap(decoded);
  }

  Future<Map<String, dynamic>> recordResult({
    required String matchId,
    required String winner,
  }) async {
    final response = await _client.post(
      Uri.parse(
          '${ApiConfig.baseUrl}${ApiConfig.matchResultEndpoint(matchId)}'),
      headers: await _buildHeaders(includeAuthToken: true),
      body: jsonEncode({'winner': winner}),
    );

    final decoded = _decodeBody(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _toMatchApiException(decoded, response.statusCode);
    }

    return _asMap(decoded);
  }

  Future<Map<String, dynamic>> generateInviteLink(String matchId) async {
    final response = await _client.post(
      Uri.parse(
          '${ApiConfig.baseUrl}${ApiConfig.matchInviteLinkEndpoint(matchId)}'),
      headers: await _buildHeaders(includeAuthToken: true),
    );

    final decoded = _decodeBody(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _toMatchApiException(decoded, response.statusCode);
    }

    return _asMap(decoded);
  }

  Future<Map<String, dynamic>> getInvitePreview(String token) async {
    final response = await _client.get(
      Uri.parse(
          '${ApiConfig.baseUrl}${ApiConfig.invitePreviewEndpoint(token)}'),
      headers: await _buildHeaders(),
    );

    final decoded = _decodeBody(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _toMatchApiException(decoded, response.statusCode);
    }

    return _normalizeInvitePreview(_asMap(decoded));
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

  Map<String, dynamic> _normalizeMatch(
    Map<String, dynamic> raw, {
    String? currentUserId,
  }) {
    final venue = _asMap(raw['venue']);
    final court = _asMap(raw['court']);
    final members = _asMapList(raw['members'])
        .map(_normalizeMember)
        .toList(growable: false);
    final confirmedMembers = members
        .where((member) => member['status'] == 'confirmed')
        .toList(growable: false);
    final pendingMembers = members
        .where((member) => member['status'] == 'pending')
        .toList(growable: false);
    final currentUser = raw['currentUserMember'] is Map
        ? _asMap(raw['currentUserMember'])
        : null;

    return {
      'id': _string(raw['id']),
      'venueName': _string(venue['name']),
      'venueImage': _string(venue['cover_image_url']),
      'venueAddress': _string(venue['address']),
      'courtName': _string(court['name']),
      'courtType': _string(court['court_type']),
      'courtSurface': _string(court['surface']),
      'date': _dateLabel(raw['match_date']),
      'matchDate': _string(raw['match_date']),
      'time': _string(raw['start_time']),
      'endTime': _string(raw['end_time']),
      'spotsLeft': _toInt(raw['max_players']) - confirmedMembers.length,
      'maxPlayers': _toInt(raw['max_players']),
      'skillLevel': _skillLabel(raw['skill_filter']),
      'skillFilter': _string(raw['skill_filter']),
      'distance': _string(venue['distance']).isNotEmpty
          ? _string(venue['distance'])
          : '—',
      'friendsIn': _toInt(raw['friends_in']),
      'isOpen': raw['is_open'] == true,
      'isAdmin': raw['admin_id']?.toString() == currentUserId,
      'adminId': _string(raw['admin_id']),
      'matchGroupId': _string(raw['id']),
      'inviteToken': _string(raw['invite_token']),
      'inviteExpiresAt': _string(raw['token_expires_at']),
      'resultWinner': _string(raw['result_winner']),
      'members': members,
      'confirmedMembers': confirmedMembers,
      'pendingMembers': pendingMembers,
      'currentUserMember': currentUser,
      'venue': venue,
      'court': court,
    };
  }

  Map<String, dynamic> _normalizeInvitePreview(Map<String, dynamic> raw) {
    final venue = _asMap(raw['venue']);
    return {
      'matchGroupId': _string(raw['matchGroupId']),
      'venueName': _string(venue['name']),
      'venueAddress': _string(venue['address']),
      'venueImage': _string(venue['cover_image_url']),
      'date': _dateLabel(raw['date']),
      'startTime': _string(raw['startTime']),
      'spotsLeft': _toInt(raw['spotsLeft']),
      'skillFilter': _skillLabel(raw['skillFilter']),
    };
  }

  Map<String, dynamic> _normalizeMember(Map<String, dynamic> raw) {
    final user = _asMap(raw['user']);
    return {
      'id': _string(user['id']),
      'name': _string(user['name']),
      'avatarUrl': _string(user['profile_image_url']),
      'skillLevel': _skillLabel(user['skill_level']),
      'eloRating': _toInt(user['elo_rating']),
      'position':
          _string(raw['position']).isNotEmpty ? _string(raw['position']) : '—',
      'team': _teamLabel(raw['team_side']),
      'status': _string(raw['status']),
      'isAdmin': raw['role'] == 'admin',
    };
  }

  String _teamLabel(dynamic value) {
    final text = _string(value);
    if (text == 'A' || text == 'B') return text;
    return '—';
  }

  String _skillLabel(dynamic value) {
    final text = _string(value);
    if (text.isEmpty) return 'All';
    return text[0].toUpperCase() + text.substring(1);
  }

  String _dateLabel(dynamic value) {
    final raw = _string(value);
    if (raw.isEmpty) return '';
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;

    const months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${parsed.day.toString().padLeft(2, '0')} ${months[parsed.month - 1]} ${parsed.year}';
  }

  Future<String?> _currentUserId() async {
    final user = await _authStorage.getUser();
    return user?['id']?.toString();
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return value.cast<String, dynamic>();
    throw const MatchApiException(
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

  dynamic _extractDiscoveryList(dynamic decoded) {
    if (decoded is Map && decoded['matches'] is List) {
      return decoded['matches'];
    }
    return decoded;
  }

  Map<String, dynamic> _normalizeDiscoveryMatch(
    Map<String, dynamic> raw, {
    required double latitude,
    required double longitude,
    String? currentUserId,
  }) {
    final venue = _asOptionalMap(raw['venue']);
    final venueName = _string(raw['venueName']).isNotEmpty
        ? _string(raw['venueName'])
        : _string(venue['name']);
    final venueImage = _string(raw['venueCoverUrl']).isNotEmpty
        ? _string(raw['venueCoverUrl'])
        : _string(venue['cover_image_url']);
    final venueAddress = _string(raw['venueAddress']).isNotEmpty
        ? _string(raw['venueAddress'])
        : _string(venue['address']);
    final matchDate = _string(raw['matchDate']).isNotEmpty
        ? _string(raw['matchDate'])
        : _string(raw['match_date']);
    final startTime = _string(raw['startTime']).isNotEmpty
        ? _string(raw['startTime'])
        : _string(raw['start_time']);
    final endTime = _string(raw['endTime']).isNotEmpty
        ? _string(raw['endTime'])
        : _string(raw['end_time']);
    final skillFilter = _string(raw['skillFilter']).isNotEmpty
        ? _string(raw['skillFilter'])
        : _string(raw['skill_filter']);
    final maxPlayers = _toInt(raw['maxPlayers']) > 0
        ? _toInt(raw['maxPlayers'])
        : _toInt(raw['max_players']);
    final spotsLeft = _toInt(raw['spotsLeft']) > 0
        ? _toInt(raw['spotsLeft'])
        : maxPlayers - _asMapList(raw['members']).length;
    final venueLat = _toDouble(raw['venueLat']) != 0
        ? _toDouble(raw['venueLat'])
        : _toDouble(venue['latitude']);
    final venueLng = _toDouble(raw['venueLng']) != 0
        ? _toDouble(raw['venueLng'])
        : _toDouble(venue['longitude']);

    final distance = (venueLat == 0 && venueLng == 0)
        ? '—'
        : '${_distanceKm(latitude, longitude, venueLat, venueLng).toStringAsFixed(1)} km';

    final id = _string(raw['matchGroupId']).isNotEmpty
        ? _string(raw['matchGroupId'])
        : _string(raw['id']);

    return {
      'id': id,
      'matchGroupId': id,
      'venueName': venueName,
      'venueImage': venueImage,
      'venueAddress': venueAddress,
      'courtName': _string(raw['courtName']).isNotEmpty
          ? _string(raw['courtName'])
          : 'Open Match',
      'date': _dateLabel(matchDate),
      'matchDate': matchDate,
      'time': startTime,
      'endTime': endTime,
      'spotsLeft': spotsLeft < 0 ? 0 : spotsLeft,
      'maxPlayers': maxPlayers,
      'skillLevel': _skillLabel(skillFilter),
      'skillFilter': skillFilter,
      'distance': distance,
      'friendsIn': 0,
      'isOpen': true,
      'isAdmin': _string(raw['admin_id']) == currentUserId,
      'adminId': _string(raw['admin_id']),
      'priceNPR': _toInt(raw['price']) > 0
          ? _toInt(raw['price']).toString()
          : _toInt(raw['priceNPR']).toString(),
      'members': const <Map<String, dynamic>>[],
      'confirmedMembers': const <Map<String, dynamic>>[],
      'pendingMembers': const <Map<String, dynamic>>[],
      'currentUserMember': const <String, dynamic>{},
      'venue': {
        'name': venueName,
        'cover_image_url': venueImage,
        'address': venueAddress,
      },
      'court': {
        'name': _string(raw['courtName']),
        'court_type': _string(raw['courtType']),
        'surface': _string(raw['courtSurface']),
      },
    };
  }

  Map<String, dynamic> _asOptionalMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return value.cast<String, dynamic>();
    return const <String, dynamic>{};
  }

  double _toDouble(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  double _distanceKm(double lat1, double lon1, double lat2, double lon2) {
    const earthRadiusKm = 6371.0;
    final dLat = _degToRad(lat2 - lat1);
    final dLon = _degToRad(lon2 - lon1);
    final a = (sin(dLat / 2) * sin(dLat / 2)) +
        cos(_degToRad(lat1)) *
            cos(_degToRad(lat2)) *
            (sin(dLon / 2) * sin(dLon / 2));
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusKm * c;
  }

  double _degToRad(double deg) => deg * (pi / 180);

  MatchApiException _toMatchApiException(dynamic decoded, int statusCode) {
    if (decoded is Map) {
      final message =
          decoded['message'] ?? decoded['error'] ?? decoded['detail'];
      if (message is String && message.isNotEmpty) {
        return MatchApiException(message: message, statusCode: statusCode);
      }
    } else if (decoded is String && decoded.isNotEmpty) {
      return MatchApiException(message: decoded, statusCode: statusCode);
    }

    return MatchApiException(
      message: 'Request failed with status $statusCode',
      statusCode: statusCode,
    );
  }
}
