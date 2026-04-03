import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/config/api_config.dart';
import '../../../../core/services/player_auth_storage_service.dart';
import '../../../../core/services/player_http_client.dart';

class VenueApiException implements Exception {
  const VenueApiException({required this.message, required this.statusCode});

  final String message;
  final int statusCode;

  @override
  String toString() => 'VenueApiException($statusCode): $message';
}

class PlayerVenuesService {
  PlayerVenuesService._internal();

  static final PlayerVenuesService instance = PlayerVenuesService._internal();

  final http.Client _client = createPlayerHttpClient();
  final PlayerAuthStorageService _authStorage = PlayerAuthStorageService.instance;

  Future<List<Map<String, dynamic>>> browseVenues({
    String? query,
    int page = 1,
    int limit = 20,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.venuesEndpoint}').replace(
      queryParameters: {
        if (query != null && query.trim().isNotEmpty) 'q': query.trim(),
        'page': '$page',
        'limit': '$limit',
      },
    );

    final response = await _client.get(uri, headers: await _buildHeaders());
    final decoded = _decodeBody(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _toVenueApiException(decoded, response.statusCode);
    }

    final records = _asList(decoded);
    return records.map(_mapVenueSummary).toList(growable: false);
  }

  Future<Map<String, dynamic>> getVenueDetail(String venueId) async {
    final response = await _client.get(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.venuesEndpoint}/$venueId'),
      headers: await _buildHeaders(),
    );

    final decoded = _decodeBody(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _toVenueApiException(decoded, response.statusCode);
    }

    return _mapVenueDetail(_asMap(decoded));
  }

  Future<Map<String, dynamic>> createVenueReview({
    required String venueId,
    required String bookingId,
    required int rating,
    String? comment,
  }) async {
    final response = await _client.post(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.venuesEndpoint}/$venueId/reviews'),
      headers: await _buildHeaders(includeAuthToken: true),
      body: jsonEncode({
        'bookingId': bookingId.trim(),
        'rating': rating,
        if (comment != null && comment.trim().isNotEmpty) 'comment': comment.trim(),
      }),
    );

    final decoded = _decodeBody(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _toVenueApiException(decoded, response.statusCode);
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

  VenueApiException _toVenueApiException(dynamic decoded, int statusCode) {
    if (decoded is Map) {
      final message = decoded['message'] ?? decoded['error'] ?? decoded['detail'];
      if (message is String && message.isNotEmpty) {
        return VenueApiException(message: message, statusCode: statusCode);
      }
    } else if (decoded is String && decoded.isNotEmpty) {
      return VenueApiException(message: decoded, statusCode: statusCode);
    }

    return VenueApiException(
      message: 'Request failed with status $statusCode',
      statusCode: statusCode,
    );
  }

  Map<String, dynamic> _mapVenueSummary(Map<String, dynamic> raw) {
    final courts = _asMapList(raw['courts']).map(_mapCourtSummary).toList(growable: false);

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
    final courts = _asMapList(raw['courts']).map(_mapCourtDetail).toList(growable: false);
    final reviews = _asMapList(raw['reviews']).map(_mapReview).toList(growable: false);

    final venue = _mapVenueSummary(raw);
    venue['courts'] = courts;
    venue['reviews'] = reviews;
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
    final player = raw['player'] is Map ? _asMap(raw['player']) : const <String, dynamic>{};

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
