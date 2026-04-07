import 'package:dio/browser.dart';
import 'package:dio/dio.dart';

import 'player_dio_client_shared.dart';
import '../services/player_auth_storage_service.dart';

Dio createPlatformPlayerDioClient({bool enableAuthInterceptor = true}) {
  final dio = buildPlayerDioClient();
  final adapter = BrowserHttpClientAdapter();
  adapter.withCredentials = true;
  dio.httpClientAdapter = adapter;

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
