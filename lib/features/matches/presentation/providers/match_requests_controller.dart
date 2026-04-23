import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/player_match_models.dart';
import '../../data/services/player_match_service.dart';

final matchServiceProvider = Provider<PlayerMatchService>((ref) {
  return PlayerMatchService.instance;
});

final matchMembersProvider =
    FutureProvider.family<List<MatchMember>, String>((ref, matchId) async {
  final service = ref.read(matchServiceProvider);
  return service.getMatchMembers(matchId);
});

class MatchRequestsController
    extends StateNotifier<AsyncValue<MatchJoinRequest?>> {
  MatchRequestsController(this._service) : super(const AsyncValue.data(null));

  final PlayerMatchService _service;

  Future<void> requestToJoinMatch({
    required String matchId,
    String? position,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return _service.requestToJoinMatch(
        matchId: matchId,
        position: position,
      );
    });
  }

  Future<void> respondToJoinRequest({
    required String requestId,
    required String action,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _service.respondToJoinRequest(
        requestId: requestId,
        action: action,
      );
      // Return null after successful response
      return null;
    });
  }

  Future<void> addFriendToMatch({
    required String matchId,
    required String friendId,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _service.addFriendToMatch(
        matchId: matchId,
        friendId: friendId,
      );
      // Return null after successful addition
      return null;
    });
  }

  void reset() {
    state = const AsyncValue.data(null);
  }
}

final matchRequestsControllerProvider = StateNotifierProvider<
    MatchRequestsController, AsyncValue<MatchJoinRequest?>>((ref) {
  final service = ref.watch(matchServiceProvider);
  return MatchRequestsController(service);
});
