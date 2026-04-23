import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/booking_repository.dart';

final bookingRepositoryProvider = Provider<BookingRepository>((ref) {
  return BookingRepository();
});
