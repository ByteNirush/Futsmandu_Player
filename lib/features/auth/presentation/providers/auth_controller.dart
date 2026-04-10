import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/player_auth_models.dart';
import '../../data/repositories/player_auth_repository.dart';

final playerAuthRepositoryProvider = Provider<PlayerAuthRepository>((ref) {
  return PlayerAuthRepository();
});

final authSessionProvider =
    AsyncNotifierProvider<AuthController, PlayerAuthSession?>(
  AuthController.new,
);

class AuthController extends AsyncNotifier<PlayerAuthSession?> {
  late final PlayerAuthRepository _repository =
      ref.read(playerAuthRepositoryProvider);

  @override
  Future<PlayerAuthSession?> build() async {
    return _repository.restoreSession();
  }

  Future<PlayerAuthSession> login({
    required String email,
    required String password,
  }) async {
    final session = await _repository.login(email: email, password: password);
    state = AsyncData(session);
    return session;
  }

  Future<PlayerAuthProfile> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) {
    return _repository.register(
      name: name,
      email: email,
      phone: phone,
      password: password,
    );
  }

  Future<OtpVerificationResult> verifyOtp({
    required String userId,
    required String otp,
  }) {
    return _repository.verifyOtp(userId: userId, otp: otp);
  }

  Future<OtpVerificationResult> resendOtp({required String userId}) {
    return _repository.resendOtp(userId: userId);
  }

  Future<String> forgotPassword({required String email}) {
    return _repository.forgotPassword(email: email);
  }

  Future<String> resetPassword({
    required String token,
    required String newPassword,
  }) {
    return _repository.resetPassword(token: token, newPassword: newPassword);
  }

  Future<String> verifyEmail({required String token}) {
    return _repository.verifyEmail(token: token);
  }

  Future<PlayerAuthSession?> refreshSession() async {
    final session = await _repository.refreshSession();
    state = AsyncData(session);
    return session;
  }

  Future<void> logout() async {
    await _repository.logout();
    state = const AsyncData(null);
  }
}
