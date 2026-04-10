import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/payment_models.dart';
import 'payment_repository_provider.dart';

final paymentHistoryControllerProvider =
    AsyncNotifierProvider<PaymentHistoryController, List<PaymentHistoryItem>>(
  PaymentHistoryController.new,
);

final paymentActionControllerProvider =
    AsyncNotifierProvider.autoDispose<PaymentActionController, void>(
  PaymentActionController.new,
);

class PaymentHistoryController extends AsyncNotifier<List<PaymentHistoryItem>> {
  @override
  Future<List<PaymentHistoryItem>> build() async {
    final repository = ref.read(paymentRepositoryProvider);
    return repository.getPaymentHistory();
  }

  Future<void> refreshHistory() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(paymentRepositoryProvider);
      return repository.getPaymentHistory();
    });
  }
}

class PaymentActionController extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<KhaltiInitiationResult> initiateKhalti({
    required String bookingId,
  }) {
    return _execute(() async {
      final repository = ref.read(paymentRepositoryProvider);
      return repository.initiateKhalti(bookingId: bookingId);
    });
  }

  Future<PaymentVerificationResult> verifyKhalti({
    required String pidx,
    required String bookingId,
  }) {
    return _execute(() async {
      final repository = ref.read(paymentRepositoryProvider);
      return repository.verifyKhalti(pidx: pidx, bookingId: bookingId);
    });
  }

  Future<EsewaInitiationResult> initiateEsewa({
    required String bookingId,
  }) {
    return _execute(() async {
      final repository = ref.read(paymentRepositoryProvider);
      return repository.initiateEsewa(bookingId: bookingId);
    });
  }

  Future<PaymentVerificationResult> verifyEsewa({
    required String data,
  }) {
    return _execute(() async {
      final repository = ref.read(paymentRepositoryProvider);
      return repository.verifyEsewa(data: data);
    });
  }

  Future<T> _execute<T>(Future<T> Function() action) async {
    state = const AsyncLoading();
    try {
      final result = await action();
      state = const AsyncData(null);
      return result;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }
}
