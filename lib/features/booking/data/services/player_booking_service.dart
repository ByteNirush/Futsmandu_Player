import 'package:dio/dio.dart';

import '../../../../core/config/api_config.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/error_handler.dart';
import '../../../../core/utils/time_formatters.dart';
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
  }) async {
    try {
      final mappedType = bookingType != null && bookingType.isNotEmpty
          ? _mapBookingTypeToBackend(bookingType)
          : null;

      final response = await _apiClient.post(
        '${ApiConfig.bookingsEndpoint}/hold',
        data: {
          'courtId': courtId,
          'date': date,
          'startTime': startTime,
          if (mappedType != null) 'bookingType': mappedType,
          if (maxPlayers != null) 'maxPlayers': maxPlayers,
          if (currentPlayerCount != null)
            'currentPlayerCount': currentPlayerCount,
          if (playersNeeded != null) 'playersNeeded': playersNeeded,
          if (friendIds != null && friendIds.isNotEmpty) 'friendIds': friendIds,
          if (description != null && description.isNotEmpty)
            'description': description,
          // For PARTIAL bookings, always send SPLIT_EQUAL cost split mode
          if (mappedType == 'PARTIAL') 'costSplitMode': 'SPLIT_EQUAL',
        },
      );

      return BookingRecord.fromJson(_asMap(_unwrap(response.data)));
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
          'page': page,
          'limit': limit,
          if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
        },
      );

      final body = _asOptionalMap(response.data);
      final data = _extractBookingRecords(body);
      final meta = _extractMeta(body);

      return BookingListResult(
        items: data
            .map(_mapBookingHistoryItem)
            .map(BookingHistoryItem.fromMap)
            .toList(growable: false),
        nextCursor: _stringOrNull(meta['nextCursor']) ??
            _stringOrNull(meta['next_cursor']),
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
      final data = _asMap(_unwrap(response.data));
      // Map booking type to UI terminology
      if (data.containsKey('booking_type')) {
        data['booking_type'] =
            _mapBookingTypeToUI(_string(data['booking_type']));
      }
      return BookingDetail(data);
    } on DioException catch (error) {
      throw _toBookingApiException(error);
    }
  }

  Future<Map<String, dynamic>> joinBooking({
    required String bookingId,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiConfig.joinBookingEndpoint(bookingId),
      );
      final data = _unwrap(response.data);
      return data is Map
          ? data.cast<String, dynamic>()
          : const <String, dynamic>{};
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

  String _mapBookingTypeToBackend(String uiType) {
    return switch (uiType.toUpperCase()) {
      'FULL_TEAM' => 'FULL',
      'PARTIAL_TEAM' => 'PARTIAL',
      'FLEX' => 'FLEX',
      'FULL' => 'FULL',
      'PARTIAL' => 'PARTIAL',
      _ => uiType, // Pass through unknown types as-is
    };
  }

  String _mapBookingTypeToUI(String backendType) {
    return switch (backendType.toUpperCase()) {
      'FULL' => 'FULL_TEAM',
      'PARTIAL' => 'PARTIAL_TEAM',
      'FLEX' => 'FLEX',
      'FULL_TEAM' => 'FULL_TEAM',
      'PARTIAL_TEAM' => 'PARTIAL_TEAM',
      _ => backendType,
    };
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

  List<Map<String, dynamic>> _extractBookingRecords(Map<String, dynamic> body) {
    final rootData = body['data'];
    if (rootData is List) {
      return _asMapList(rootData);
    }

    if (rootData is Map) {
      final payload = _asOptionalMap(rootData);
      if (payload['data'] is List) {
        return _asMapList(payload['data']);
      }
      if (payload['items'] is List) {
        return _asMapList(payload['items']);
      }
      if (payload['records'] is List) {
        return _asMapList(payload['records']);
      }
    }

    if (body['items'] is List) {
      return _asMapList(body['items']);
    }
    if (body['records'] is List) {
      return _asMapList(body['records']);
    }

    return const <Map<String, dynamic>>[];
  }

  Map<String, dynamic> _extractMeta(Map<String, dynamic> body) {
    if (body['meta'] is Map) {
      return _asOptionalMap(body['meta']);
    }

    final rootData = body['data'];
    if (rootData is Map) {
      final payload = _asOptionalMap(rootData);
      if (payload['meta'] is Map) {
        return _asOptionalMap(payload['meta']);
      }
    }

    return const <String, dynamic>{};
  }

  Map<String, dynamic> _mapBookingHistoryItem(Map<String, dynamic> raw) {
    final court = _asOptionalMap(raw['court']);
    final venue = _asOptionalMap(court['venue']);
    final payment = _asOptionalMap(raw['payment']);
    final matchGroup = _asOptionalMap(raw['match_group']);
    final durationMins = _toInt(raw['duration_mins']);

    // Resolve match group ID — may live under different keys depending on API version
    final matchGroupId = _string(matchGroup['id']).isNotEmpty
        ? _string(matchGroup['id'])
        : _string(raw['match_group_id']);

    return {
      'id': _string(raw['id']),
      'status': _string(raw['status']),
      'date': _dateLabel(raw['booking_date']),
      'time': _timeRange(_string(raw['start_time']), _string(raw['end_time'])),
      'duration': durationMins > 0 ? '$durationMins mins' : '-',
      'priceNPR': _toMoney(raw['total_amount']),
      'displayAmount': _string(raw['displayAmount']),
      'venueName': _string(venue['name']),
      'courtName': _string(court['name']),
      'startTime': _string(raw['start_time']),
      'endTime': _string(raw['end_time']),
      'bookingDate': _string(raw['booking_date']),
      'refundStatus': _string(raw['refund_status']),
      'refundAmount': _toInt(raw['refund_amount']),
      'paymentGateway': _string(payment['gateway']),
      'paymentStatus': _string(payment['status']),
      'venueAddress': _string(venue['address']),
      'venueId': _string(venue['id']),
      'courtId': _string(court['id']),
      'bookingType': _mapBookingTypeToUI(_string(raw['booking_type'])),
      'matchGroupId': matchGroupId,
      'maxPlayers': _toInt(raw['max_players']),
      'myPlayers': _toInt(raw['my_players']),
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
    final amount = _toInt(value);
    return (amount / 100).toStringAsFixed(0);
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
    return formatClockTimeRange12Hour(start, end);
  }
}
