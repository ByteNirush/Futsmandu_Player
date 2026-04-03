import 'package:http/http.dart' as http;

import 'player_http_client_stub.dart'
    if (dart.library.html) 'player_http_client_web.dart';

http.Client createPlayerHttpClient() => createPlatformHttpClient();