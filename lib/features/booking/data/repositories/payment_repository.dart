import '../models/payment_models.dart';
import '../services/player_payments_service.dart';

class PaymentRepository {
  PaymentRepository({PlayerPaymentsService? service})
      : _service = service ?? PlayerPaymentsService.instance;

  final PlayerPaymentsService _service;

  Future<KhaltiInitiationResult> initiateKhalti({
    required String bookingId,
  }) {
    return _service.initiateKhalti(bookingId: bookingId);
  }

  Future<PaymentVerificationResult> verifyKhalti({
    required String pidx,
    required String bookingId,
  }) {
    return _service.verifyKhalti(
      pidx: pidx,
      bookingId: bookingId,
    );
  }

  Future<EsewaInitiationResult> initiateEsewa({
    required String bookingId,
  }) {
    return _service.initiateEsewa(bookingId: bookingId);
  }

  Future<PaymentVerificationResult> verifyEsewa({
    required String data,
  }) {
    return _service.verifyEsewa(data: data);
  }

  Future<PaymentDetail> getPayment(String paymentId) {
    return _service.getPayment(paymentId);
  }

  Future<List<PaymentHistoryItem>> getPaymentHistory() {
    return _service.getPaymentHistory();
  }
}
