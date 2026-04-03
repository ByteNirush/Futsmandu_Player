import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/config/api_config.dart';
import '../../../../core/services/player_auth_storage_service.dart';
import '../../../../core/services/player_http_client.dart';

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

  final List<Map<String, dynamic>> items;
  final String? nextCursor;
  final int limit;
}

class PlayerBookingService {
  PlayerBookingService._internal();

  static final PlayerBookingService instance = PlayerBookingService._internal();

  final http.Client _client = createPlayerHttpClient();
  final PlayerAuthStorageService _authStorage =
      PlayerAuthStorageService.instance;

  Future<List<Map<String, dynamic>>> getAvailability({
    required String venueId,
    required String courtId,
    required String date,
  }) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.venueAvailabilityEndpoint(venueId)}',
    ).replace(
      queryParameters: {
        'courtId': courtId,
        'date': date,
      },
    );

    final response = await _client.get(uri, headers: await _buildHeaders());
    final decoded = _decodeBody(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _toBookingApiException(decoded, response.statusCode);
    }

    final records = _asMapList(decoded);
    return records
        .map(
          (slot) => {
            'time': _string(slot['startTime']),
            'endTime': _string(slot['endTime']),
            'status': _normalizeSlotStatus(_string(slot['status'])),
          },
        )
        .toList(growable: false);
  }

  Future<Map<String, dynamic>> holdSlot({
    required String courtId,
    required String date,
    required String startTime,
    List<String>? friendIds,
  }) async {
    final response = await _client.post(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.bookingsEndpoint}/hold'),
      headers: await _buildHeaders(includeAuthToken: true),
      body: jsonEncode({
        'courtId': courtId,
        'date': date,
        'startTime': startTime,
        if (friendIds != null && friendIds.isNotEmpty) 'friendIds': friendIds,
      }),
    );

    final decoded = _decodeBody(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _toBookingApiException(decoded, response.statusCode);
    }

    return _asMap(decoded);
  }

  Future<BookingListResult> getBookings({
    String? status,
    int page = 1,
    int limit = 20,
    String? cursor,
  }) async {
    final uri =
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.bookingsEndpoint}').replace(
      queryParameters: {
        if (status != null && status.isNotEmpty) 'status': status,
        'page': '$page',
        'limit': '$limit',
        if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
      },
    );

    final response = await _client.get(
      uri,
      headers: await _buildHeaders(includeAuthToken: true),
    );

    final decoded = _decodeBody(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _toBookingApiException(decoded, response.statusCode);
    }

    final payload = _asMap(decoded);
    final data = _asMapList(payload['data']);
    final meta = _asMap(payload['meta']);

    return BookingListResult(
      items: data.map(_mapBookingHistoryItem).toList(growable: false),
      nextCursor: _stringOrNull(meta['nextCursor']),
      limit: _toInt(meta['limit']) == 0 ? limit : _toInt(meta['limit']),
    );
  }

  Future<Map<String, dynamic>> getBookingDetail(String bookingId) async {
    final response = await _client.get(
      Uri.parse(
          '${ApiConfig.baseUrl}${ApiConfig.bookingDetailEndpoint(bookingId)}'),
      headers: await _buildHeaders(includeAuthToken: true),
    );

    final decoded = _decodeBody(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _toBookingApiException(decoded, response.statusCode);
    }

    return _asMap(decoded);
  }

  Future<Map<String, dynamic>> cancelBooking({
    required String bookingId,
    String? reason,
  }) async {
    final response = await _client.post(
      Uri.parse(
          '${ApiConfig.baseUrl}${ApiConfig.cancelBookingEndpoint(bookingId)}'),
      headers: await _buildHeaders(includeAuthToken: true),
      body: jsonEncode({
        if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
      }),
    );

    final decoded = _decodeBody(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _toBookingApiException(decoded, response.statusCode);
    }

    return _asMap(decoded);
  }

  Future<Map<String, String>> _buildHeaders({
    bool includeAuthToken = false,
  }) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (includeAuthToken) {
      final token = await _authStorage.getAccessToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  dynamic _decodeBody(String body) {
    final trimmed = body.trim();
    if (trimmed.isEmpty) return null;

    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is Map && decoded.containsKey('data')) {
        return decoded['data'];
      }
      return decoded;
    } catch (_) {
      return trimmed;
    }
  }

  BookingApiException _toBookingApiException(dynamic decoded, int statusCode) {
    if (decoded is Map) {
      final message =
          decoded['message'] ?? decoded['error'] ?? decoded['detail'];
      if (message is String && message.isNotEmpty) {
        return BookingApiException(message: message, statusCode: statusCode);
      }
    } else if (decoded is String && decoded.isNotEmpty) {
      return BookingApiException(message: decoded, statusCode: statusCode);
    }

    return BookingApiException(
      message: 'Request failed with status $statusCode',
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

  String _normalizeSlotStatus(String status) {
    return status == 'AVAILABLE' ? 'AVAILABLE' : 'UNAVAILABLE';
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
