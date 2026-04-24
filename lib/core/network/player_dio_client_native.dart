import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../services/player_auth_storage_service.dart';
import 'player_dio_client_shared.dart';

Dio createPlatformPlayerDioClient({bool enableAuthInterceptor = true}) {
  final dio = buildPlayerDioClient();

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
