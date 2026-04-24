import 'package:flutter/foundation.dart';

class AppLogger {
  static const String _prefix = '[Futsmandu]';

  static void log(String message, {String? tag}) {
    if (kDebugMode) {
      final tagStr = tag != null ? '[$tag]' : '';
      debugPrint('$_prefix$tagStr $message');
    }
  }

  static void info(String message, {String? tag}) {
    log('ℹ️ INFO: $message', tag: tag);
  }

  static void warning(String message, {String? tag}) {
    log('⚠️ WARN: $message', tag: tag);
  }

  static void error(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    log('❌ ERROR: $message', tag: tag);
    if (error != null) {
      debugPrint('$_prefix Error details: $error');
    }
    if (stackTrace != null) {
      debugPrint('$_prefix Stack trace:\n$stackTrace');
    }
  }

  static void api(String method, String url, {Object? body, Object? response}) {
    if (kDebugMode) {
      debugPrint('$_prefix 🌐 API [$method] $url');
      if (body != null) debugPrint('$_prefix 📤 Request: $body');
      if (response != null) debugPrint('$_prefix 📥 Response: $response');
    }
  }
}
