import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:typed_data';

import '../../data/models/player_profile_models.dart';
import '../../data/services/player_profile_service.dart';

final playerProfileServiceProvider = Provider<PlayerProfileService>((ref) {
  return PlayerProfileService.instance;
});

final ownProfileControllerProvider =
    AsyncNotifierProvider<OwnProfileController, PlayerProfile?>(
  OwnProfileController.new,
);

final publicProfileProvider =
    FutureProvider.family<PublicPlayerProfile, String>((ref, userId) async {
  final service = ref.read(playerProfileServiceProvider);
  return service.getPublicProfile(userId);
});

class OwnProfileController extends AsyncNotifier<PlayerProfile?> {
  late final PlayerProfileService _service =
      ref.read(playerProfileServiceProvider);

  @override
  Future<PlayerProfile?> build() async {
    return _service.getOwnProfile();
  }

  Future<void> refreshProfile() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_service.getOwnProfile);
  }

  Future<PlayerProfile> updateProfile(UpdateProfileRequest request) async {
    final updated = await _service.updateOwnProfile(request);
    state = AsyncData(updated);
    return updated;
  }

  Future<PlayerProfile> uploadAvatar(Uint8List bytes) async {
    await _service.uploadAvatarBytes(bytes);
    final updated = await _service.getOwnProfile();
    state = AsyncData(updated);
    return updated;
  }
}
