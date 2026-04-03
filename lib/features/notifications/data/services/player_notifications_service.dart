import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/config/api_config.dart';
import '../../../../core/services/player_auth_storage_service.dart';
import '../../../../core/services/player_http_client.dart';

class NotificationsApiException implements Exception {
  const NotificationsApiException({
    required this.message,
    required this.statusCode,
  });

  final String message;
  final int statusCode;

  @override
  String toString() => 'NotificationsApiException($statusCode): $message';
}

class PlayerNotificationsService {
  PlayerNotificationsService._internal();

  static final PlayerNotificationsService instance =
      PlayerNotificationsService._internal();

  final http.Client _client = createPlayerHttpClient();
  final PlayerAuthStorageService _authStorage =
      PlayerAuthStorageService.instance;

  Future<List<Map<String, dynamic>>> getNotifications({
    int page = 1,
    int limit = 30,
  }) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.notificationsEndpoint}',
    ).replace(
      queryParameters: {
        'page': '$page',
        'limit': '$limit',
      },
    );

    final response = await _client.get(
      uri,
      headers: await _buildHeaders(includeAuthToken: true),
    );

    final decoded = _decodeBody(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _toNotificationsApiException(decoded, response.statusCode);
    }

    final payload = _asMap(decoded);
    final items = _asMapList(payload['data']);
    return items.map(_normalizeNotification).toList(growable: false);
  }

  Future<void> markAllRead() async {
    final response = await _client.put(
      Uri.parse(
          '${ApiConfig.baseUrl}${ApiConfig.markAllNotificationsReadEndpoint}'),
      headers: await _buildHeaders(includeAuthToken: true),
    );

    final decoded = _decodeBody(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _toNotificationsApiException(decoded, response.statusCode);
    }
  }

  Future<void> markOneRead({required String notificationId}) async {
    final response = await _client.put(
      Uri.parse(
        '${ApiConfig.baseUrl}${ApiConfig.markNotificationReadEndpoint(notificationId)}',
      ),
      headers: await _buildHeaders(includeAuthToken: true),
    );

    final decoded = _decodeBody(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _toNotificationsApiException(decoded, response.statusCode);
    }
  }

  Future<Map<String, String>> _buildHeaders({
    bool includeAuthToken = false,
  }) async {
    final headers = <String, String>{
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

  Map<String, dynamic> _normalizeNotification(Map<String, dynamic> raw) {
    final createdAt = _parseDate(raw['created_at']);
    return {
      'id': _string(raw['id']),
      'type': _string(raw['type']),
      'title': _string(raw['title']),
      'body': _string(raw['body']),
      'isRead': _bool(raw['is_read']),
      'timeAgo': _formatTimeAgo(createdAt),
      'createdAt': createdAt,
    };
  }

  dynamic _decodeBody(String body) {
    final trimmed = body.trim();
    if (trimmed.isEmpty) return null;

    try {
      return jsonDecode(trimmed);
    } catch (_) {
      return trimmed;
    }
  }

  NotificationsApiException _toNotificationsApiException(
    dynamic decoded,
    int statusCode,
  ) {
    if (decoded is Map) {
      final message =
          decoded['message'] ?? decoded['error'] ?? decoded['detail'];
      if (message is String && message.isNotEmpty) {
        return NotificationsApiException(
            message: message, statusCode: statusCode);
      }

      final nestedData = decoded['data'];
      if (nestedData is Map) {
        final nestedMessage = nestedData['message'] ??
            nestedData['error'] ??
            nestedData['detail'];
        if (nestedMessage is String && nestedMessage.isNotEmpty) {
          return NotificationsApiException(
            message: nestedMessage,
            statusCode: statusCode,
          );
        }
      }
    } else if (decoded is String && decoded.isNotEmpty) {
      return NotificationsApiException(
          message: decoded, statusCode: statusCode);
    }

    return NotificationsApiException(
      message: 'Request failed with status $statusCode',
      statusCode: statusCode,
    );
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return value.cast<String, dynamic>();
    throw const NotificationsApiException(
      message: 'Unexpected server response',
      statusCode: 500,
    );
  }

  List<Map<String, dynamic>> _asMapList(dynamic value) {
    if (value is! List) return const <Map<String, dynamic>>[];
    return value.map(_asMap).toList(growable: false);
  }

  String _string(dynamic value) {
    if (value is String) return value;
    return '';
  }

  bool _bool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      return value.toLowerCase() == 'true' || value == '1';
    }
    return false;
  }

  DateTime? _parseDate(dynamic value) {
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value)?.toLocal();
    }
    return null;
  }

  String _formatTimeAgo(DateTime? date) {
    if (date == null) return '';
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) {
      final mins = diff.inMinutes;
      return mins == 1 ? '1 min ago' : '$mins mins ago';
    }
    if (diff.inHours < 24) {
      final hours = diff.inHours;
      return hours == 1 ? '1 hr ago' : '$hours hrs ago';
    }
    if (diff.inDays < 7) {
      final days = diff.inDays;
      return days == 1 ? 'Yesterday' : '$days days ago';
    }
    final weeks = (diff.inDays / 7).floor();
    if (weeks < 5) {
      return weeks == 1 ? '1 week ago' : '$weeks weeks ago';
    }
    return '${date.year}-${_twoDigits(date.month)}-${_twoDigits(date.day)}';
  }

  String _twoDigits(int value) => value.toString().padLeft(2, '0');
}
