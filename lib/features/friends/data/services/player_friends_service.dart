import 'package:dio/dio.dart';

import '../../../../core/config/api_config.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/error_handler.dart';
import '../models/player_friends_models.dart';

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

  final ApiClient _client = ApiClient.instance;

  Future<List<Friend>> fetchFriends() async {
    try {
      final response = await _client.get(ApiConfig.friendsEndpoint);

      final records = _asMapList(_unwrap(response.data));
      return records.map((raw) {
        final friendData = _asMap(raw['friend']);
        return Friend.fromMap({
          ...friendData,
          'friendshipId': _string(raw['friendshipId']),
          'since': _string(raw['since']),
          'id': _string(friendData['id']),
          'name': _string(friendData['name']),
          'avatarUrl': _string(friendData['profile_image_url']),
          'skillLevel': _skillLabel(friendData['skill_level']),
          'eloRating': _toInt(friendData['elo_rating']),
          'matchesPlayed': 0,
          'reliabilityScore': 70,
        });
      }).toList(growable: false);
    } on DioException catch (error) {
      throw _toFriendsApiExceptionFromDio(error);
    }
  }

  Future<List<Map<String, dynamic>>> getFriends() async {
    final friends = await fetchFriends();
    return friends.map((item) => item.toMap()).toList(growable: false);
  }

  Future<List<FriendRequest>> fetchFriendRequests() async {
    try {
      final response =
          await _client.get('${ApiConfig.friendsEndpoint}/requests');

      final records = _asMapList(_unwrap(response.data));
      return records.map((raw) {
        final requesterData = _asMap(raw['requester']);
        return FriendRequest.fromMap({
          'id': _string(requesterData['id']),
          'friendshipId': _string(raw['id']),
          'name': _string(requesterData['name']),
          'avatarUrl': _string(requesterData['profile_image_url']),
          'skillLevel': _skillLabel(requesterData['skill_level']),
          'mutualFriends': 0,
        });
      }).toList(growable: false);
    } on DioException catch (error) {
      throw _toFriendsApiExceptionFromDio(error);
    }
  }

  Future<List<Map<String, dynamic>>> getFriendRequests() async {
    final requests = await fetchFriendRequests();
    return requests.map((item) => item.toMap()).toList(growable: false);
  }

  Future<List<SearchPlayer>> searchPlayers({
    required String query,
    int limit = 10,
  }) async {
    try {
      final response = await _client.get(
        '${ApiConfig.friendsEndpoint}/search',
        queryParameters: {
          'q': query,
          'limit': '$limit',
        },
      );

      final records = _asMapList(_unwrap(response.data));
      return records
          .map((raw) => SearchPlayer.fromMap({
                'id': _string(raw['id']),
                'name': _string(raw['name']),
                'avatarUrl': _string(raw['profile_image_url']),
                'skillLevel': _skillLabel(raw['skill_level']),
                'eloRating': _toInt(raw['elo_rating']),
                'matchesPlayed': 0,
                'status': 'unknown',
              }))
          .toList(growable: false);
    } on DioException catch (error) {
      throw _toFriendsApiExceptionFromDio(error);
    }
  }

  Future<List<Map<String, dynamic>>> searchPlayersLegacy({
    required String query,
    int limit = 10,
  }) async {
    final players = await searchPlayers(query: query, limit: limit);
    return players.map((item) => item.toMap()).toList(growable: false);
  }

  Future<FriendRequestResult> sendFriendRequest({
    required String recipientId,
  }) async {
    try {
      final response = await _client.post(
        '${ApiConfig.friendsEndpoint}/request',
        data: {'recipientId': recipientId},
      );

      return FriendRequestResult.fromMap(_asMap(_unwrap(response.data)));
    } on DioException catch (error) {
      throw _toFriendsApiExceptionFromDio(error);
    }
  }

  Future<FriendRequestResult> acceptFriendRequest({
    required String friendshipId,
  }) async {
    try {
      final response = await _client.put(
        ApiConfig.acceptFriendRequestEndpoint(friendshipId),
        data: const <String, dynamic>{},
      );

      return FriendRequestResult.fromMap(_asMap(_unwrap(response.data)));
    } on DioException catch (error) {
      throw _toFriendsApiExceptionFromDio(error);
    }
  }

  Future<void> removeFriend({
    required String friendshipId,
  }) async {
    try {
      await _client.delete(
        ApiConfig.friendByIdEndpoint(friendshipId),
      );
    } on DioException catch (error) {
      throw _toFriendsApiExceptionFromDio(error);
    }
  }

  Future<Map<String, dynamic>> removeFriendshipLegacy({
    required String friendshipId,
  }) async {
    try {
      final response = await _client.delete(
        ApiConfig.friendByIdEndpoint(friendshipId),
      );
      final data = _unwrap(response.data);
      return data is Map ? data.cast<String, dynamic>() : const {};
    } on DioException catch (error) {
      throw _toFriendsApiExceptionFromDio(error);
    }
  }

  Future<BlockResult> blockPlayer({
    required String playerId,
  }) async {
    try {
      final response = await _client.post(
        ApiConfig.blockPlayerEndpoint(playerId),
      );

      return BlockResult.fromMap(_asMap(_unwrap(response.data)));
    } on DioException catch (error) {
      throw _toFriendsApiExceptionFromDio(error);
    }
  }

  dynamic _unwrap(dynamic body) {
    if (body is Map && body.containsKey('data')) {
      return body['data'];
    }
    return body;
  }

  FriendsApiException _toFriendsApiExceptionFromDio(DioException error) {
    return FriendsApiException(
      message: ErrorHandler.messageFor(error),
      statusCode: error.response?.statusCode ?? 500,
    );
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map) return value.cast<String, dynamic>();
    return const <String, dynamic>{};
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
