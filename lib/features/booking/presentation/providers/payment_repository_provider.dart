import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/payment_repository.dart';

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return PaymentRepository();
});
