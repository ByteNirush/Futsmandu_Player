import 'package:dio/dio.dart';

import '../../../../core/config/api_config.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/error_handler.dart';

class VenueApiException implements Exception {
  const VenueApiException({required this.message, required this.statusCode});

  final String message;
  final int statusCode;

  @override
  String toString() => 'VenueApiException($statusCode): $message';
}

class VenueBrowseResult {
  const VenueBrowseResult({
    required this.items,
    required this.page,
    required this.limit,
    required this.hasMore,
  });

  final List<Map<String, dynamic>> items;
  final int page;
  final int limit;
  final bool hasMore;
}

class PlayerVenuesService {
  PlayerVenuesService._internal();

  static final PlayerVenuesService instance = PlayerVenuesService._internal();

  final ApiClient _apiClient = ApiClient.instance;

  Future<List<Map<String, dynamic>>> browseVenues({
    String? query,
    int page = 1,
    int limit = 20,
  }) async {
    final result =
        await browseVenuesPage(query: query, page: page, limit: limit);
    return result.items;
  }

  Future<VenueBrowseResult> browseVenuesPage({
    String? query,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _apiClient.get(
        ApiConfig.venuesEndpoint,
        queryParameters: {
          if (query != null && query.trim().isNotEmpty) 'q': query.trim(),
          'page': '$page',
          'limit': '$limit',
        },
      );

      final records = _asList(_unwrap(response.data));
      final items = records.map(_mapVenueSummary).toList(growable: false);

      return VenueBrowseResult(
        items: items,
        page: page,
        limit: limit,
        hasMore: items.length >= limit,
      );
    } on DioException catch (error) {
      throw _toVenueApiException(error);
    }
  }

  Future<Map<String, dynamic>> getVenueDetail(String venueId) async {
    try {
      final response =
          await _apiClient.get('${ApiConfig.venuesEndpoint}/$venueId');
      return _mapVenueDetail(_asMap(_unwrap(response.data)));
    } on DioException catch (error) {
      throw _toVenueApiException(error);
    }
  }

  Future<List<Map<String, dynamic>>> getVenueAvailability({
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

      final records = _asList(_unwrap(response.data));
      return records
          .map(
            (slot) => {
              'time': _string(slot['startTime']),
              'endTime': _string(slot['endTime']),
              'status': _normalizeSlotStatus(_string(slot['status'])),
            },
          )
          .toList(growable: false);
    } on DioException catch (error) {
      throw _toVenueApiException(error);
    }
  }

  Future<Map<String, dynamic>> createVenueReview({
    required String venueId,
    required String bookingId,
    required int rating,
    String? comment,
  }) async {
    try {
      final response = await _apiClient.post(
        '${ApiConfig.venuesEndpoint}/$venueId/reviews',
        data: {
          'bookingId': bookingId.trim(),
          'rating': rating,
          if (comment != null && comment.trim().isNotEmpty)
            'comment': comment.trim(),
        },
      );

      return _asMap(_unwrap(response.data));
    } on DioException catch (error) {
      throw _toVenueApiException(error);
    }
  }

  dynamic _unwrap(dynamic body) {
    if (body is Map && body.containsKey('data')) {
      return body['data'];
    }
    return body;
  }

  List<Map<String, dynamic>> _asList(dynamic value) {
    if (value is List) {
      return value.map(_asMap).toList(growable: false);
    }
    throw const VenueApiException(
      message: 'Unexpected server response',
      statusCode: 500,
    );
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return value.cast<String, dynamic>();
    throw const VenueApiException(
      message: 'Unexpected server response',
      statusCode: 500,
    );
  }

  VenueApiException _toVenueApiException(DioException error) {
    final statusCode = error.response?.statusCode ?? 500;
    return VenueApiException(
      message: ErrorHandler.messageFor(error),
      statusCode: statusCode,
    );
  }

  Map<String, dynamic> _mapVenueSummary(Map<String, dynamic> raw) {
    final courts =
        _asMapList(raw['courts']).map(_mapCourtSummary).toList(growable: false);

    return {
      'id': _string(raw['id']),
      'name': _string(raw['name']),
      'slug': _string(raw['slug']),
      'description': _string(raw['description']),
      'address': _string(raw['address']),
      'lat': _toDouble(raw['latitude']),
      'lng': _toDouble(raw['longitude']),
      'coverUrl': _string(raw['cover_image_url']),
      'rating': _toDouble(raw['avg_rating']),
      'reviewCount': _toInt(raw['total_reviews']),
      'amenities': _asStringList(raw['amenities']),
      'courts': courts,
      'isVerified': true,
    };
  }

  Map<String, dynamic> _mapVenueDetail(Map<String, dynamic> raw) {
    final courts =
        _asMapList(raw['courts']).map(_mapCourtDetail).toList(growable: false);
    final reviews =
        _asMapList(raw['reviews']).map(_mapReview).toList(growable: false);

    final owner = raw['owner'] is Map
        ? _asMap(raw['owner'])
        : const <String, dynamic>{};

    final venue = _mapVenueSummary(raw);
    venue['courts'] = courts;
    venue['reviews'] = reviews;
    venue['ownerPhone'] = _string(owner['phone']);
    return venue;
  }

  Map<String, dynamic> _mapCourtSummary(Map<String, dynamic> raw) {
    return {
      'id': _string(raw['id']),
      'name': _string(raw['name']),
      'type': _string(raw['court_type']),
      'surface': _string(raw['surface']),
      'slotDurationMins': _toInt(raw['slot_duration_mins']),
      'slots': const <Map<String, dynamic>>[],
    };
  }

  Map<String, dynamic> _mapCourtDetail(Map<String, dynamic> raw) {
    final summary = _mapCourtSummary(raw);
    summary['capacity'] = _toInt(raw['capacity']);
    summary['minPlayers'] = _toInt(raw['min_players']);
    summary['openTime'] = _string(raw['open_time']);
    summary['closeTime'] = _string(raw['close_time']);
    return summary;
  }

  Map<String, dynamic> _mapReview(Map<String, dynamic> raw) {
    final player = raw['player'] is Map
        ? _asMap(raw['player'])
        : const <String, dynamic>{};

    return {
      'id': _string(raw['id']),
      'author': _string(player['name']),
      'authorAvatarUrl': _string(player['profile_image_url']),
      'rating': _toDouble(raw['rating']),
      'text': _string(raw['comment']),
      'ownerReply': _string(raw['owner_reply']),
      'date': _dateLabel(raw['created_at']),
    };
  }

  List<Map<String, dynamic>> _asMapList(dynamic value) {
    if (value is! List) return const <Map<String, dynamic>>[];
    return value.map((item) {
      if (item is Map<String, dynamic>) return item;
      if (item is Map) return item.cast<String, dynamic>();
      return <String, dynamic>{};
    }).toList(growable: false);
  }

  List<String> _asStringList(dynamic value) {
    if (value is! List) return const <String>[];
    return value.whereType<String>().toList(growable: false);
  }

  String _string(dynamic value) {
    if (value is String) return value;
    return '';
  }

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return 0;
  }

  int _toInt(dynamic value) {
    if (value is num) return value.toInt();
    return 0;
  }

  String _normalizeSlotStatus(String status) {
    final normalized = status.toUpperCase();
    if (normalized == 'AVAILABLE') return 'AVAILABLE';
    return 'UNAVAILABLE';
  }

  String _dateLabel(dynamic value) {
    if (value is! String || value.isEmpty) return '';
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return value;
    final month = _monthAbbr(parsed.month);
    return '${parsed.day.toString().padLeft(2, '0')} $month';
  }

  String _monthAbbr(int month) {
    const names = <String>[
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
    if (month < 1 || month > 12) return '';
    return names[month - 1];
  }
}
