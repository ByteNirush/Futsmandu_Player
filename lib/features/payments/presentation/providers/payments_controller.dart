import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/player_payment_models.dart';
import '../../data/services/player_payment_service.dart';

final paymentServiceProvider = Provider<PlayerPaymentService>((ref) {
  return PlayerPaymentService.instance;
});

final paymentHistoryProvider = FutureProvider<List<Payment>>((ref) async {
  final service = ref.read(paymentServiceProvider);
  return service.getPaymentHistory();
});

final paymentDetailProvider =
    FutureProvider.family<Payment, String>((ref, paymentId) async {
  final service = ref.read(paymentServiceProvider);
  return service.getPaymentDetail(paymentId);
});

class PaymentActionController
    extends StateNotifier<AsyncValue<PaymentVerifyResult?>> {
  PaymentActionController(this._service) : super(const AsyncValue.data(null));

  final PlayerPaymentService _service;

  Future<void> initiateKhaltiPayment({
    required int amount,
    required String productName,
    String? productIdentity,
    String? returnUrl,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _service.initiateKhaltiPayment(
        amount: amount,
        productName: productName,
        productIdentity: productIdentity,
        returnUrl: returnUrl,
      );
      return null;
    });
  }

  Future<void> verifyKhaltiPayment({
    required String pidx,
    required String transactionId,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return await _service.verifyKhaltiPayment(
        pidx: pidx,
        transactionId: transactionId,
      );
    });
  }

  Future<void> initiateESewaPayment({
    required int amount,
    required String productName,
    String? productIdentity,
    String? returnUrl,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _service.initiateESewaPayment(
        amount: amount,
        productName: productName,
        productIdentity: productIdentity,
        returnUrl: returnUrl,
      );
      return null;
    });
  }

  Future<void> verifyESewaPayment({
    required String referenceId,
    required String decodedProductData,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return await _service.verifyESewaPayment(
        referenceId: referenceId,
        decodedProductData: decodedProductData,
      );
    });
  }

  void reset() {
    state = const AsyncValue.data(null);
  }
}

final paymentActionControllerProvider = StateNotifierProvider<
    PaymentActionController, AsyncValue<PaymentVerifyResult?>>((ref) {
  return PaymentActionController(ref.read(paymentServiceProvider));
});
