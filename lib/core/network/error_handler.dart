import 'package:dio/dio.dart';

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class ErrorHandler {
  const ErrorHandler._();

  static String messageFor(Object error) {
    if (error is ApiException) {
      return error.message;
    }

    if (error is DioException) {
      if (error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout) {
        return 'Unable to connect. Please check your internet and try again.';
      }

      final data = error.response?.data;
      if (data is Map<String, dynamic>) {
        final nestedData = data['data'];
        if (nestedData is Map<String, dynamic>) {
          final nestedMessage = nestedData['message']?.toString();
          if (nestedMessage != null && nestedMessage.trim().isNotEmpty) {
            return nestedMessage;
          }
        }

        final message = data['message']?.toString();
        if (message != null && message.trim().isNotEmpty) {
          return message;
        }

        final errorText = data['error']?.toString();
        if (errorText != null && errorText.trim().isNotEmpty) {
          return errorText;
        }
      }

      if (data is String && data.trim().isNotEmpty) {
        return data;
      }

      if (error.message != null && error.message!.trim().isNotEmpty) {
        return error.message!;
      }
    }

    final message = error.toString();
    return message.replaceFirst('Exception: ', '');
  }
}
