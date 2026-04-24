import 'package:dio/browser.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'player_dio_client_shared.dart';
import '../services/player_auth_storage_service.dart';

Dio createPlatformPlayerDioClient({bool enableAuthInterceptor = true}) {
  final dio = buildPlayerDioClient();
  final adapter = BrowserHttpClientAdapter();
  adapter.withCredentials = true;
  dio.httpClientAdapter = adapter;

  if (kDebugMode) {
    dio.interceptors.add(
      LogInterceptor(
        request: true,
        requestHeader: true,
        requestBody: true,
        responseHeader: true,
        responseBody: true,
        error: true,
        logPrint: (object) => debugPrint(object.toString()),
      ),
    );
  }

  if (enableAuthInterceptor) {
    dio.interceptors.add(
      PlayerAuthInterceptor(
        storage: PlayerAuthStorageService.instance,
        refreshClient:
            createPlatformPlayerDioClient(enableAuthInterceptor: false),
      ),
    );
  }

  return dio;
}
