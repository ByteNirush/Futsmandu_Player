import 'package:dio/dio.dart';

import 'player_dio_client_native.dart'
    if (dart.library.html) 'player_dio_client_web.dart';

Dio createPlayerDioClient({bool enableAuthInterceptor = true}) =>
    createPlatformPlayerDioClient(enableAuthInterceptor: enableAuthInterceptor);
