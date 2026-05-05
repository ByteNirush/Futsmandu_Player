import '../models/booking_models.dart';
import '../services/player_booking_service.dart';

class BookingRepository {
  BookingRepository({PlayerBookingService? service})
      : _service = service ?? PlayerBookingService.instance;

  final PlayerBookingService _service;

  Future<List<BookingAvailabilitySlot>> getAvailability({
    required String venueId,
    required String courtId,
    required String date,
  }) {
    return _service.getAvailability(
      venueId: venueId,
      courtId: courtId,
      date: date,
    );
  }

  Future<BookingRecord> createBooking({
    required String courtId,
    required String date,
    required String startTime,
    String? bookingType,
    int? maxPlayers,
    int? currentPlayerCount,
    int? playersNeeded,
    List<String>? friendIds,
    String? description,
  }) {
    return _service.createBooking(
      courtId: courtId,
      date: date,
      startTime: startTime,
      bookingType: bookingType,
      maxPlayers: maxPlayers,
      currentPlayerCount: currentPlayerCount,
      playersNeeded: playersNeeded,
      friendIds: friendIds,
      description: description,
    );
  }

  Future<BookingListResult> getBookings({
    String? status,
    int page = 1,
    int limit = 20,
    String? cursor,
  }) {
    return _service.getBookings(
      status: status,
      page: page,
      limit: limit,
      cursor: cursor,
    );
  }

  Future<BookingDetail> getBookingDetail(String bookingId) {
    return _service.getBookingDetail(bookingId);
  }

  Future<Map<String, dynamic>> joinBooking({required String bookingId}) {
    return _service.joinBooking(bookingId: bookingId);
  }

  Future<BookingCancellationResult> cancelBooking({
    required String bookingId,
    String? reason,
  }) {
    return _service.cancelBooking(bookingId: bookingId, reason: reason);
  }
}
