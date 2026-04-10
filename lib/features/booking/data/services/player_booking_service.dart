import 'package:dio/dio.dart';

import '../../../../core/config/api_config.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/error_handler.dart';
import '../models/booking_models.dart';

class BookingApiException implements Exception {
  const BookingApiException({required this.message, required this.statusCode});

  final String message;
  final int statusCode;

  @override
  String toString() => 'BookingApiException($statusCode): $message';
}

class BookingListResult {
  const BookingListResult({
    required this.items,
    required this.nextCursor,
    required this.limit,
  });

  final List<BookingHistoryItem> items;
  final String? nextCursor;
  final int limit;
}

class PlayerBookingService {
  PlayerBookingService._internal();

  static final PlayerBookingService instance = PlayerBookingService._internal();

  final ApiClient _apiClient = ApiClient.instance;

  Future<List<BookingAvailabilitySlot>> getAvailability({
    required String venueId,
    required String courtId,
    required String date,
  }) async {
    try {
      final response = await _apiClient.get(
        ApiConfig.venueAvailabilityEndpoint(venueId),
        queryParameters: {
          'courtId': courtId,
          'date': date,
        },
      );
      final records = _asMapList(_unwrap(response.data));
      return records
          .map(BookingAvailabilitySlot.fromJson)
          .toList(growable: false);
    } on DioException catch (error) {
      throw _toBookingApiException(error);
    }
  }

  Future<HeldBooking> holdSlot({
    required String courtId,
    required String date,
    required String startTime,
    List<String>? friendIds,
  }) async {
    try {
      final response = await _apiClient.post(
        '${ApiConfig.bookingsEndpoint}/hold',
        data: {
          'courtId': courtId,
          'date': date,
          'startTime': startTime,
          if (friendIds != null && friendIds.isNotEmpty) 'friendIds': friendIds,
        },
      );

      return HeldBooking.fromJson(_asMap(_unwrap(response.data)));
    } on DioException catch (error) {
      throw _toBookingApiException(error);
    }
  }

  Future<BookingListResult> getBookings({
    String? status,
    int page = 1,
    int limit = 20,
    String? cursor,
  }) async {
    try {
      final response = await _apiClient.get(
        ApiConfig.bookingsEndpoint,
        queryParameters: {
          if (status != null && status.isNotEmpty) 'status': status,
          'page': '$page',
          'limit': '$limit',
          if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
        },
      );

      final payload = _asMap(_unwrap(response.data));
      final data = _asMapList(payload['data']);
      final meta = _asMap(payload['meta']);

      return BookingListResult(
        items: data
            .map(_mapBookingHistoryItem)
            .map(BookingHistoryItem.fromMap)
            .toList(growable: false),
        nextCursor: _stringOrNull(meta['nextCursor']),
        limit: _toInt(meta['limit']) == 0 ? limit : _toInt(meta['limit']),
      );
    } on DioException catch (error) {
      throw _toBookingApiException(error);
    }
  }

  Future<BookingDetail> getBookingDetail(String bookingId) async {
    try {
      final response =
          await _apiClient.get(ApiConfig.bookingDetailEndpoint(bookingId));
      return BookingDetail(_asMap(_unwrap(response.data)));
    } on DioException catch (error) {
      throw _toBookingApiException(error);
    }
  }

  Future<BookingCancellationResult> cancelBooking({
    required String bookingId,
    String? reason,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiConfig.cancelBookingEndpoint(bookingId),
        data: {
          if (reason != null && reason.trim().isNotEmpty)
            'reason': reason.trim(),
        },
      );
      return BookingCancellationResult.fromJson(_asMap(_unwrap(response.data)));
    } on DioException catch (error) {
      throw _toBookingApiException(error);
    }
  }

  dynamic _unwrap(dynamic body) {
    if (body is Map && body.containsKey('data')) {
      return body['data'];
    }
    return body;
  }

  BookingApiException _toBookingApiException(DioException error) {
    final statusCode = error.response?.statusCode ?? 500;
    return BookingApiException(
      message: ErrorHandler.messageFor(error),
      statusCode: statusCode,
    );
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return value.cast<String, dynamic>();
    throw const BookingApiException(
      message: 'Unexpected server response',
      statusCode: 500,
    );
  }

  List<Map<String, dynamic>> _asMapList(dynamic value) {
    if (value is! List) return const <Map<String, dynamic>>[];
    return value.map(_asMap).toList(growable: false);
  }

  Map<String, dynamic> _mapBookingHistoryItem(Map<String, dynamic> raw) {
    final court = _asMap(raw['court']);
    final venue = _asMap(court['venue']);
    final payment = _asOptionalMap(raw['payment']);

    return {
      'id': _string(raw['id']),
      'status': _string(raw['status']),
      'date': _dateLabel(raw['booking_date']),
      'time': _timeRange(_string(raw['start_time']), _string(raw['end_time'])),
      'duration': '${_toInt(raw['duration_mins'])} mins',
      'priceNPR': _toMoney(raw['total_amount']),
      'displayAmount': _string(raw['displayAmount']),
      'venueName': _string(venue['name']),
      'courtName': _string(court['name']),
      'startTime': _string(raw['start_time']),
      'endTime': _string(raw['end_time']),
      'bookingDate': _string(raw['booking_date']),
      'refundStatus': _string(raw['refund_status']),
      'refundAmount': _toInt(raw['refund_amount']),
      'holdExpiresAt': _string(raw['hold_expires_at']),
      'paymentGateway': _string(payment['gateway']),
      'paymentStatus': _string(payment['status']),
      'venueAddress': _string(venue['address']),
      'venueId': _string(venue['id']),
      'courtId': _string(court['id']),
    };
  }

  Map<String, dynamic> _asOptionalMap(dynamic value) {
    if (value == null) return const <String, dynamic>{};
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return value.cast<String, dynamic>();
    return const <String, dynamic>{};
  }

  String _string(dynamic value) {
    if (value is String) return value;
    return '';
  }

  String? _stringOrNull(dynamic value) {
    if (value is String && value.isNotEmpty) return value;
    return null;
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  String _toMoney(dynamic value) {
    return _toInt(value).toString();
  }

  String _dateLabel(dynamic rawDate) {
    final date = _string(rawDate);
    if (date.isEmpty) return '-';
    final parsed = DateTime.tryParse(date);
    if (parsed == null) return date;

    const months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${parsed.day.toString().padLeft(2, '0')} ${months[parsed.month - 1]} ${parsed.year}';
  }

  String _timeRange(String start, String end) {
    if (start.isEmpty && end.isEmpty) return '-';
    if (end.isEmpty) return start;
    return '$start - $end';
  }
}
