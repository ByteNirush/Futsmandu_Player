import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/player_friends_models.dart';
import '../../data/services/player_friends_service.dart';

final friendsServiceProvider = Provider<PlayerFriendsService>((ref) {
  return PlayerFriendsService.instance;
});

final friendsListProvider = FutureProvider<List<Friend>>((ref) async {
  final service = ref.read(friendsServiceProvider);
  return service.fetchFriends();
});

final friendRequestsProvider = FutureProvider<List<FriendRequest>>((ref) async {
  final service = ref.read(friendsServiceProvider);
  return service.fetchFriendRequests();
});

final searchPlayersProvider =
    FutureProvider.family<List<SearchPlayer>, (String query, int limit)>(
        (ref, params) async {
  final service = ref.read(friendsServiceProvider);
  if (params.$1.isEmpty) return const [];
  return service.searchPlayers(query: params.$1, limit: params.$2);
});

class FriendsActionController extends StateNotifier<AsyncValue<void>> {
  FriendsActionController(this._service) : super(const AsyncValue.data(null));

  final PlayerFriendsService _service;

  Future<void> sendFriendRequest({
    required String recipientId,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _service.sendFriendRequest(recipientId: recipientId);
    });
  }

  Future<void> acceptFriendRequest({
    required String friendshipId,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _service.acceptFriendRequest(friendshipId: friendshipId);
    });
  }

  Future<void> removeFriend({
    required String friendshipId,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _service.removeFriend(friendshipId: friendshipId);
    });
  }

  Future<void> blockPlayer({
    required String playerId,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _service.blockPlayer(playerId: playerId);
    });
  }

  void reset() {
    state = const AsyncValue.data(null);
  }
}

final friendsActionControllerProvider =
    StateNotifierProvider<FriendsActionController, AsyncValue<void>>(
  (ref) => FriendsActionController(ref.read(friendsServiceProvider)),
);
