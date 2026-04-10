import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/api_config.dart';
import '../services/player_auth_storage_service.dart';

const String _authPrefix = '/api/v1/player/auth';

Dio buildPlayerDioClient() {
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 20),
      sendTimeout: const Duration(seconds: 20),
      headers: const {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ),
  );

  return dio;
}

class PlayerAuthInterceptor extends QueuedInterceptorsWrapper {
  PlayerAuthInterceptor({
    required PlayerAuthStorageService storage,
    required Dio refreshClient,
  })  : _storage = storage,
        _refreshClient = refreshClient;

  final PlayerAuthStorageService _storage;
  final Dio _refreshClient;
  Completer<String?>? _refreshCompleter;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final path = _normalizedPath(options.path);
    final isAuthRoute = path.startsWith(_authPrefix);

    if (!isAuthRoute) {
      final token = await _storage.getAccessToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }

    if (path == '$_authPrefix/refresh' && !kIsWeb) {
      final refreshToken = await _storage.getRefreshToken();
      if (refreshToken != null && refreshToken.isNotEmpty) {
        options.headers['Cookie'] = 'refreshToken=$refreshToken';
      }
    }

    handler.next(options);
  }

  @override
  Future<void> onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) async {
    await _persistRefreshToken(response);
    handler.next(response);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final response = err.response;
    final requestOptions = err.requestOptions;
    final path = _normalizedPath(requestOptions.path);

    if (response?.statusCode != 401 || path.startsWith(_authPrefix)) {
      handler.next(err);
      return;
    }

    final alreadyRetried = requestOptions.extra['authRetry'] == true;
    if (alreadyRetried) {
      await _storage.clearSession();
      handler.next(err);
      return;
    }

    final refreshed = await _refreshAccessToken();
    if (refreshed == null || refreshed.isEmpty) {
      await _storage.clearSession();
      handler.next(err);
      return;
    }

    requestOptions.extra['authRetry'] = true;
    requestOptions.headers['Authorization'] = 'Bearer $refreshed';

    try {
      final retryResponse = await _refreshClient.fetch(requestOptions);
      handler.resolve(retryResponse);
    } on DioException catch (retryError) {
      await _storage.clearSession();
      handler.next(retryError);
    }
  }

  Future<String?> _refreshAccessToken() async {
    if (_refreshCompleter != null) {
      return _refreshCompleter!.future;
    }

    final completer = Completer<String?>();
    _refreshCompleter = completer;

    try {
      final response = await _refreshClient.post<Map<String, dynamic>>(
        '/api/v1/player/auth/refresh',
        options: Options(headers: await _buildRefreshHeaders()),
      );
      final accessToken = _extractAccessToken(response.data);
      if (accessToken != null && accessToken.isNotEmpty) {
        await _storage.saveAccessToken(accessToken);
      }
      await _persistRefreshToken(response);
      completer.complete(accessToken);
    } on DioException {
      completer.complete(null);
    } catch (_) {
      completer.complete(null);
    } finally {
      _refreshCompleter = null;
    }

    return completer.future;
  }

  Future<void> _persistRefreshToken(Response response) async {
    final headerValues = response.headers.map['set-cookie'];
    if (headerValues != null && headerValues.isNotEmpty) {
      for (final header in headerValues) {
        final refreshToken = _extractRefreshToken(header);
        if (refreshToken != null && refreshToken.isNotEmpty) {
          await _storage.saveRefreshToken(refreshToken);
          return;
        }
      }
    }

    final refreshToken = _extractRefreshToken(response.data);
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await _storage.saveRefreshToken(refreshToken);
    }
  }

  Future<Map<String, String>> _buildRefreshHeaders() async {
    final headers = <String, String>{};
    if (!kIsWeb) {
      final refreshToken = await _storage.getRefreshToken();
      if (refreshToken != null && refreshToken.isNotEmpty) {
        headers['Cookie'] = 'refreshToken=$refreshToken';
      }
    }
    return headers;
  }

  String? _extractAccessToken(dynamic decoded) {
    final map = _payloadMap(decoded);
    final token = map['accessToken'];
    return token is String && token.isNotEmpty ? token : null;
  }

  String? _extractRefreshToken(dynamic decoded) {
    if (decoded is String) {
      final match = RegExp(r'refreshToken=([^;]+)').firstMatch(decoded);
      if (match != null) {
        return Uri.decodeComponent(match.group(1) ?? '');
      }
      return null;
    }

    final map = _payloadMap(decoded);
    final token = map['refreshToken'];
    return token is String && token.isNotEmpty ? token : null;
  }

  Map<String, dynamic> _payloadMap(dynamic value) {
    final map = _asMap(value);
    final data = map['data'];
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is Map) {
      return data.cast<String, dynamic>();
    }
    return map;
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return value.cast<String, dynamic>();
    return const <String, dynamic>{};
  }

  String _normalizedPath(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      final uri = Uri.tryParse(path);
      if (uri != null) return uri.path;
    }
    return path;
  }
}
