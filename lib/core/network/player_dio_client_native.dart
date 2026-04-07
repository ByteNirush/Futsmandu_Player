import 'package:dio/dio.dart';

import '../services/player_auth_storage_service.dart';
import 'player_dio_client_shared.dart';

Dio createPlatformPlayerDioClient({bool enableAuthInterceptor = true}) {
  final dio = buildPlayerDioClient();

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
