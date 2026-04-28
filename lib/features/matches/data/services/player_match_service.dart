import 'dart:math';

import 'package:dio/dio.dart';

import '../../../../core/config/api_config.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/error_handler.dart';
import '../../../../core/services/player_auth_storage_service.dart';
import '../models/player_match_models.dart';

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

  final ApiClient _client = ApiClient.instance;
  final PlayerAuthStorageService _authStorage =
      PlayerAuthStorageService.instance;

  Future<List<MatchSummary>> fetchTonightMatches({
    double latitude = 0,
    double longitude = 0,
  }) async {
    return _fetchDiscoveryMatches(
      ApiConfig.tonightMatchesEndpoint,
      latitude: latitude,
      longitude: longitude,
    );
  }

  Future<List<MatchSummary>> fetchTomorrowMatches({
    double latitude = 0,
    double longitude = 0,
  }) async {
    return _fetchDiscoveryMatches(
      ApiConfig.tomorrowMatchesEndpoint,
      latitude: latitude,
      longitude: longitude,
    );
  }

  Future<List<MatchSummary>> fetchWeekendMatches({
    double latitude = 0,
    double longitude = 0,
  }) async {
    return _fetchDiscoveryMatches(
      ApiConfig.weekendMatchesEndpoint,
      latitude: latitude,
      longitude: longitude,
    );
  }

  Future<List<MatchSummary>> fetchOpenMatches({
    String? date,
    String? skill,
    int limit = 20,
    double latitude = 0,
    double longitude = 0,
  }) async {
    try {
      final response = await _client.get(
        ApiConfig.openMatchesEndpoint,
        queryParameters: {
          if (date != null && date.isNotEmpty) 'date': date,
          if (skill != null && skill.isNotEmpty) 'skill': skill,
          'limit': '$limit',
          'lat': '$latitude',
          'lng': '$longitude',
        },
      );

      final currentUserId = await _currentUserId();
      final records = _asMapList(_extractDiscoveryList(_unwrap(response.data)));
      return records
          .map(
            (raw) => MatchSummary.fromMap(
              _normalizeDiscoveryMatch(
                raw,
                latitude: latitude,
                longitude: longitude,
                currentUserId: currentUserId,
              ),
            ),
          )
          .toList(growable: false);
    } on DioException catch (error) {
      throw _toMatchApiExceptionFromDio(error);
    }
  }

  Future<List<Map<String, dynamic>>> getTonightMatches({
    double latitude = 0,
    double longitude = 0,
  }) async {
    final items = await fetchTonightMatches(
      latitude: latitude,
      longitude: longitude,
    );
    return items.map((item) => item.toMap()).toList(growable: false);
  }

  Future<List<Map<String, dynamic>>> getTomorrowMatches({
    double latitude = 0,
    double longitude = 0,
  }) async {
    final items = await fetchTomorrowMatches(
      latitude: latitude,
      longitude: longitude,
    );
    return items.map((item) => item.toMap()).toList(growable: false);
  }

  Future<List<Map<String, dynamic>>> getWeekendMatches({
    double latitude = 0,
    double longitude = 0,
  }) async {
    final items = await fetchWeekendMatches(
      latitude: latitude,
      longitude: longitude,
    );
    return items.map((item) => item.toMap()).toList(growable: false);
  }

  Future<List<Map<String, dynamic>>> getOpenMatches({
    String? date,
    String? skill,
    int limit = 20,
    double latitude = 0,
    double longitude = 0,
  }) async {
    final items = await fetchOpenMatches(
      date: date,
      skill: skill,
      limit: limit,
      latitude: latitude,
      longitude: longitude,
    );
    return items.map((item) => item.toMap()).toList(growable: false);
  }

  Future<MatchDetail> fetchMatch(String matchId) async {
    try {
      final response =
          await _client.get(ApiConfig.matchDetailEndpoint(matchId));
      final currentUserId = await _currentUserId();
      final normalized = _normalizeMatch(_asMap(_unwrap(response.data)),
          currentUserId: currentUserId);
      return MatchDetail.fromMap(normalized);
    } on DioException catch (error) {
      throw _toMatchApiExceptionFromDio(error);
    }
  }

  Future<Map<String, dynamic>> getMatch(String matchId) async {
    final detail = await fetchMatch(matchId);
    return detail.toMap();
  }

  Future<Map<String, dynamic>> joinMatch({
    required String matchId,
    String? position,
  }) async {
    try {
      final response = await _client.post(
        ApiConfig.joinMatchEndpoint(matchId),
        data: {
          if (position != null && position.isNotEmpty) 'position': position,
        },
      );

      final data = _unwrap(response.data);
      return data is Map
          ? data.cast<String, dynamic>()
          : const <String, dynamic>{};
    } on DioException catch (error) {
      throw _toMatchApiExceptionFromDio(error);
    }
  }

  Future<Map<String, dynamic>> approveMember({
    required String matchId,
    required String userId,
  }) async {
    try {
      final response = await _client.put(
        ApiConfig.approveMatchMemberEndpoint(matchId, userId),
      );
      final data = _unwrap(response.data);
      return data is Map
          ? data.cast<String, dynamic>()
          : const <String, dynamic>{};
    } on DioException catch (error) {
      throw _toMatchApiExceptionFromDio(error);
    }
  }

  Future<Map<String, dynamic>> rejectMember({
    required String matchId,
    required String userId,
  }) async {
    try {
      final response = await _client.put(
        ApiConfig.rejectMatchMemberEndpoint(matchId, userId),
      );
      final data = _unwrap(response.data);
      return data is Map
          ? data.cast<String, dynamic>()
          : const <String, dynamic>{};
    } on DioException catch (error) {
      throw _toMatchApiExceptionFromDio(error);
    }
  }

  Future<Map<String, dynamic>> leaveMatch(String matchId) async {
    try {
      final response =
          await _client.delete(ApiConfig.leaveMatchEndpoint(matchId));
      final data = _unwrap(response.data);
      return data is Map
          ? data.cast<String, dynamic>()
          : const <String, dynamic>{};
    } on DioException catch (error) {
      throw _toMatchApiExceptionFromDio(error);
    }
  }

  Future<Map<String, dynamic>> updateTeams({
    required String matchId,
    required List<String> teamA,
    required List<String> teamB,
  }) async {
    try {
      final response = await _client.put(
        ApiConfig.updateMatchTeamsEndpoint(matchId),
        data: {
          'A': teamA,
          'B': teamB,
        },
      );
      final data = _unwrap(response.data);
      return data is Map
          ? data.cast<String, dynamic>()
          : const <String, dynamic>{};
    } on DioException catch (error) {
      throw _toMatchApiExceptionFromDio(error);
    }
  }

  Future<Map<String, dynamic>> recordResult({
    required String matchId,
    required String winner,
  }) async {
    try {
      final response = await _client.post(
        ApiConfig.matchResultEndpoint(matchId),
        data: {'winner': winner},
      );
      final data = _unwrap(response.data);
      return data is Map
          ? data.cast<String, dynamic>()
          : const <String, dynamic>{};
    } on DioException catch (error) {
      throw _toMatchApiExceptionFromDio(error);
    }
  }

  Future<MatchInviteLink> fetchInviteLink(String matchId) async {
    try {
      final response = await _client.post(
        ApiConfig.matchInviteLinkEndpoint(matchId),
        data: {},
      );
      return MatchInviteLink.fromMap(_asMap(_unwrap(response.data)));
    } on DioException catch (error) {
      throw _toMatchApiExceptionFromDio(error);
    }
  }

  Future<Map<String, dynamic>> generateInviteLink(String matchId) async {
    final invite = await fetchInviteLink(matchId);
    return invite.toMap();
  }

  Future<MatchInvitePreview> fetchInvitePreview(String token) async {
    try {
      final response =
          await _client.get(ApiConfig.invitePreviewEndpoint(token));
      final normalized =
          _normalizeInvitePreview(_asMap(_unwrap(response.data)));
      return MatchInvitePreview.fromMap(normalized);
    } on DioException catch (error) {
      throw _toMatchApiExceptionFromDio(error);
    }
  }

  Future<Map<String, dynamic>> getInvitePreview(String token) async {
    final preview = await fetchInvitePreview(token);
    return preview.toMap();
  }

  Future<MatchJoinRequest> requestToJoinMatch({
    required String matchId,
    String? position,
  }) async {
    try {
      final response = await _client.post(
        '${ApiConfig.matchesEndpoint}/join',
        data: {
          'matchGroupId': matchId,
          if (position != null && position.isNotEmpty) 'position': position,
        },
      );

      return MatchJoinRequest.fromMap(_asMap(_unwrap(response.data)));
    } on DioException catch (error) {
      throw _toMatchApiExceptionFromDio(error);
    }
  }

  Future<MatchJoinResponse> respondToJoinRequest({
    required String requestId,
    required String action,
  }) async {
    try {
      final normalizedAction = action.trim().toUpperCase();
      final response = await _client.post(
        '${ApiConfig.matchesEndpoint}/join-requests/$requestId/respond',
        data: {'action': normalizedAction},
      );

      return MatchJoinResponse.fromMap(_asMap(_unwrap(response.data)));
    } on DioException catch (error) {
      throw _toMatchApiExceptionFromDio(error);
    }
  }

  Future<List<MatchMember>> getMatchMembers(String matchId) async {
    try {
      final response = await _client.get(
        '${ApiConfig.matchesEndpoint}/$matchId/members',
      );

      final records = _asMapList(_unwrap(response.data));
      return records.map(MatchMember.fromMap).toList(growable: false);
    } on DioException catch (error) {
      throw _toMatchApiExceptionFromDio(error);
    }
  }

  Future<MatchMemberAddResult> addFriendToMatch({
    required String matchId,
    required String friendId,
  }) async {
    try {
      final response = await _client.post(
        '${ApiConfig.matchesEndpoint}/$matchId/members/add-friend',
        data: {'friendId': friendId},
      );

      return MatchMemberAddResult.fromMap(_asMap(_unwrap(response.data)));
    } on DioException catch (error) {
      throw _toMatchApiExceptionFromDio(error);
    }
  }

  Future<List<MatchSummary>> _fetchDiscoveryMatches(
    String endpoint, {
    required double latitude,
    required double longitude,
  }) async {
    try {
      final response = await _client.get(
        endpoint,
        queryParameters: {
          'lat': '$latitude',
          'lng': '$longitude',
        },
      );

      final currentUserId = await _currentUserId();
      final records = _asMapList(_extractDiscoveryList(_unwrap(response.data)));
      return records
          .map(
            (raw) => MatchSummary.fromMap(
              _normalizeDiscoveryMatch(
                raw,
                latitude: latitude,
                longitude: longitude,
                currentUserId: currentUserId,
              ),
            ),
          )
          .toList(growable: false);
    } on DioException catch (error) {
      throw _toMatchApiExceptionFromDio(error);
    }
  }

  dynamic _unwrap(dynamic body) {
    if (body is Map && body.containsKey('data')) {
      return body['data'];
    }
    return body;
  }

  MatchApiException _toMatchApiExceptionFromDio(DioException error) {
    return MatchApiException(
      message: ErrorHandler.messageFor(error),
      statusCode: error.response?.statusCode ?? 500,
    );
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
    final maxPlayers = _toInt(raw['max_players']);
    final confirmedCount = confirmedMembers.length;
    final slotsAvailable = (maxPlayers - confirmedCount).clamp(0, maxPlayers);
    final fillStatus = _string(raw['fill_status']).isNotEmpty
      ? _string(raw['fill_status'])
      : (slotsAvailable == 0 ? 'FULL' : 'OPEN');
    final costSplitMode = _string(raw['cost_split_mode']);
    final description = _string(raw['description']);
    final isPartialTeamBooking =
      costSplitMode.isNotEmpty || description.isNotEmpty || 
      raw['booking_type'] == 'PARTIAL_TEAM' || raw['booking_type'] == 'PARTIAL';

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
        'spotsLeft': slotsAvailable,
        'maxPlayers': maxPlayers,
        'memberCount': confirmedCount,
        'slotsAvailable': slotsAvailable,
        'playersNeeded': slotsAvailable,
      'skillLevel': _skillLabel(raw['skill_filter']),
      'skillFilter': _string(raw['skill_filter']),
      'distance': _string(venue['distance']).isNotEmpty
          ? _string(venue['distance'])
          : '—',
        'fillStatus': fillStatus,
        'costSplitMode': costSplitMode,
        'description': description,
        'isPartialTeamBooking': isPartialTeamBooking,
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
    if (decoded is Map && decoded['data'] is List) {
      return decoded['data'];
    }
    if (decoded is Map && decoded['items'] is List) {
      return decoded['items'];
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
    final court = _asOptionalMap(raw['court']);
    final admin = _asOptionalMap(raw['admin']);
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
    final memberCount = _toInt(raw['memberCount']) > 0
      ? _toInt(raw['memberCount'])
      : _toInt(raw['membersCount']);
    final slotsAvailable = _toInt(raw['slotsAvailable']) > 0
      ? _toInt(raw['slotsAvailable'])
      : _toInt(raw['availableSlots']);
    final spotsLeft = _toInt(raw['spotsLeft']) > 0
        ? _toInt(raw['spotsLeft'])
      : (slotsAvailable > 0 ? slotsAvailable : maxPlayers - memberCount);
    final normalizedSpotsLeft = spotsLeft < 0 ? 0 : spotsLeft;
    final fillStatus = _string(raw['fillStatus']).isNotEmpty
      ? _string(raw['fillStatus'])
      : (normalizedSpotsLeft == 0 ? 'FULL' : 'OPEN');
    final costSplitMode = _string(raw['costSplitMode']);
    final description = _string(raw['description']);
    final isPartialTeamBooking =
      costSplitMode.isNotEmpty || description.isNotEmpty || 
      raw['bookingType'] == 'PARTIAL_TEAM' || raw['booking_type'] == 'PARTIAL_TEAM' ||
      raw['bookingType'] == 'PARTIAL' || raw['booking_type'] == 'PARTIAL';
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
          : (_string(court['name']).isNotEmpty
            ? _string(court['name'])
            : 'Open Match'),
      'date': _dateLabel(matchDate),
      'matchDate': matchDate,
      'time': startTime,
      'endTime': endTime,
      'spotsLeft': normalizedSpotsLeft,
      'maxPlayers': maxPlayers,
      'memberCount': memberCount,
      'slotsAvailable': normalizedSpotsLeft,
      'playersNeeded': normalizedSpotsLeft,
      'skillLevel': _skillLabel(skillFilter),
      'skillFilter': skillFilter,
      'distance': distance,
      'fillStatus': fillStatus,
      'costSplitMode': costSplitMode,
      'description': description,
      'isPartialTeamBooking': isPartialTeamBooking,
      'friendsIn': 0,
      'isOpen': true,
        'isAdmin': (_string(raw['admin_id']).isNotEmpty
            ? _string(raw['admin_id'])
            : _string(admin['id'])) ==
          currentUserId,
        'adminId': _string(raw['admin_id']).isNotEmpty
          ? _string(raw['admin_id'])
          : _string(admin['id']),
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
        'name': _string(raw['courtName']).isNotEmpty
            ? _string(raw['courtName'])
            : _string(court['name']),
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
}
