import 'package:dio/dio.dart';

import '../../../../core/config/api_config.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/error_handler.dart';
import '../models/player_notification_models.dart';

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

  final ApiClient _client = ApiClient.instance;

  Future<NotificationsPage> getNotifications({
    int page = 1,
    int limit = 30,
  }) async {
    try {
      final response = await _client.get(
        ApiConfig.notificationsEndpoint,
        queryParameters: {
          'page': page,
          'limit': limit,
        },
      );

      final body = _asMap(response.data);
      final payload = _unwrapData(body);
      final records = _extractNotificationRecords(payload);
      final items = records
          .map(PlayerNotification.fromMap)
          .toList(growable: false);

      final hasMore = _resolveHasMore(
        body: body,
        payload: payload,
        page: page,
        limit: limit,
        fetchedCount: items.length,
      );

      return NotificationsPage(
        items: items,
        page: page,
        limit: limit,
        hasMore: hasMore,
      );
    } on DioException catch (error) {
      throw _toNotificationsApiExceptionFromDio(error);
    }
  }

  Future<void> markAllRead() async {
    try {
      await _client.put(ApiConfig.markAllNotificationsReadEndpoint);
    } on DioException catch (error) {
      throw _toNotificationsApiExceptionFromDio(error);
    }
  }

  Future<void> markOneRead({required String notificationId}) async {
    try {
      await _client.put(ApiConfig.markNotificationReadEndpoint(notificationId));
    } on DioException catch (error) {
      throw _toNotificationsApiExceptionFromDio(error);
    }
  }

  dynamic _unwrapData(Map<String, dynamic> body) {
    if (body.containsKey('data')) {
      return body['data'];
    }
    return body;
  }

  List<Map<String, dynamic>> _extractNotificationRecords(dynamic payload) {
    if (payload is List) return _asMapList(payload);

    if (payload is Map) {
      final mapPayload = payload.cast<String, dynamic>();
      final items = mapPayload['items'];
      if (items is List) return _asMapList(items);

      final records = mapPayload['records'];
      if (records is List) return _asMapList(records);

      final notifications = mapPayload['notifications'];
      if (notifications is List) return _asMapList(notifications);
    }

    return const <Map<String, dynamic>>[];
  }

  bool _resolveHasMore({
    required Map<String, dynamic> body,
    required dynamic payload,
    required int page,
    required int limit,
    required int fetchedCount,
  }) {
    final meta = _extractMeta(body, payload);

    final hasMoreFlag = _boolFromUnknown(meta['hasMore']) ??
        _boolFromUnknown(meta['hasNext']) ??
        _boolFromUnknown(meta['hasNextPage']);
    if (hasMoreFlag != null) {
      return hasMoreFlag;
    }

    final nextPage = _intFromUnknown(meta['nextPage']);
    if (nextPage != null) {
      return nextPage > page;
    }

    final total = _intFromUnknown(meta['total']) ?? _intFromUnknown(meta['count']);
    if (total != null && total >= 0) {
      return (page * limit) < total;
    }

    return fetchedCount >= limit;
  }

  Map<String, dynamic> _extractMeta(Map<String, dynamic> body, dynamic payload) {
    if (body['meta'] is Map) {
      return _asMap(body['meta']);
    }

    if (payload is Map) {
      final mapPayload = _asMap(payload);
      if (mapPayload['meta'] is Map) {
        return _asMap(mapPayload['meta']);
      }
    }

    return const <String, dynamic>{};
  }

  NotificationsApiException _toNotificationsApiExceptionFromDio(
    DioException error,
  ) {
    return NotificationsApiException(
      message: ErrorHandler.messageFor(error),
      statusCode: error.response?.statusCode ?? 500,
    );
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return value.cast<String, dynamic>();
    return const <String, dynamic>{};
  }

  List<Map<String, dynamic>> _asMapList(dynamic value) {
    if (value is! List) return const <Map<String, dynamic>>[];
    return value.map(_asMap).toList(growable: false);
  }

  int? _intFromUnknown(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  bool? _boolFromUnknown(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == 'true' || normalized == '1') return true;
      if (normalized == 'false' || normalized == '0') return false;
    }
    return null;
  }
}
