import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/config/api_config.dart';
import '../../../../core/services/player_auth_storage_service.dart';
import '../../../../core/services/player_http_client.dart';

class PaymentsApiException implements Exception {
  const PaymentsApiException({required this.message, required this.statusCode});

  final String message;
  final int statusCode;

  @override
  String toString() => 'PaymentsApiException($statusCode): $message';
}

class PlayerPaymentsService {
  PlayerPaymentsService._internal();

  static final PlayerPaymentsService instance =
      PlayerPaymentsService._internal();

  final http.Client _client = createPlayerHttpClient();
  final PlayerAuthStorageService _authStorage =
      PlayerAuthStorageService.instance;

  Future<Map<String, dynamic>> initiateKhalti({
    required String bookingId,
  }) async {
    final response = await _client.post(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.khaltiInitiateEndpoint}'),
      headers: await _buildHeaders(includeAuthToken: true),
      body: jsonEncode({'bookingId': bookingId}),
    );

    final decoded = _decodeBody(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _toPaymentsApiException(decoded, response.statusCode);
    }

    return _asMap(decoded);
  }

  Future<Map<String, dynamic>> verifyKhalti({
    required String pidx,
    required String bookingId,
  }) async {
    final response = await _client.post(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.khaltiVerifyEndpoint}'),
      headers: await _buildHeaders(includeAuthToken: true),
      body: jsonEncode({
        'pidx': pidx,
        'bookingId': bookingId,
      }),
    );

    final decoded = _decodeBody(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _toPaymentsApiException(decoded, response.statusCode);
    }

    return _asMap(decoded);
  }

  Future<Map<String, dynamic>> initiateEsewa({
    required String bookingId,
  }) async {
    final response = await _client.post(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.esewaInitiateEndpoint}'),
      headers: await _buildHeaders(includeAuthToken: true),
      body: jsonEncode({'bookingId': bookingId}),
    );

    final decoded = _decodeBody(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _toPaymentsApiException(decoded, response.statusCode);
    }

    return _asMap(decoded);
  }

  Future<Map<String, dynamic>> verifyEsewa({
    required String data,
  }) async {
    final response = await _client.post(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.esewaVerifyEndpoint}'),
      headers: await _buildHeaders(includeAuthToken: true),
      body: jsonEncode({'data': data}),
    );

    final decoded = _decodeBody(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _toPaymentsApiException(decoded, response.statusCode);
    }

    return _asMap(decoded);
  }

  Future<Map<String, dynamic>> getPayment(String paymentId) async {
    final response = await _client.get(
      Uri.parse(
          '${ApiConfig.baseUrl}${ApiConfig.paymentDetailEndpoint(paymentId)}'),
      headers: await _buildHeaders(
          includeAuthToken: true, includeJsonContentType: false),
    );

    final decoded = _decodeBody(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _toPaymentsApiException(decoded, response.statusCode);
    }

    return _asMap(decoded);
  }

  Future<List<Map<String, dynamic>>> getPaymentHistory() async {
    final response = await _client.get(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.paymentHistoryEndpoint}'),
      headers: await _buildHeaders(
          includeAuthToken: true, includeJsonContentType: false),
    );

    final decoded = _decodeBody(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _toPaymentsApiException(decoded, response.statusCode);
    }

    final list = _asList(decoded);
    return list.map(_asMap).toList(growable: false);
  }

  Future<Map<String, String>> _buildHeaders({
    bool includeAuthToken = false,
    bool includeJsonContentType = true,
  }) async {
    final headers = <String, String>{
      'Accept': 'application/json',
      if (includeJsonContentType) 'Content-Type': 'application/json',
    };

    if (includeAuthToken) {
      final token = await _authStorage.getAccessToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  dynamic _decodeBody(String body) {
    final trimmed = body.trim();
    if (trimmed.isEmpty) return null;

    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is Map && decoded.containsKey('data')) {
        return decoded['data'];
      }
      return decoded;
    } catch (_) {
      return trimmed;
    }
  }

  PaymentsApiException _toPaymentsApiException(
      dynamic decoded, int statusCode) {
    if (decoded is Map) {
      final message =
          decoded['message'] ?? decoded['error'] ?? decoded['detail'];
      if (message is String && message.isNotEmpty) {
        return PaymentsApiException(message: message, statusCode: statusCode);
      }
    } else if (decoded is String && decoded.isNotEmpty) {
      return PaymentsApiException(message: decoded, statusCode: statusCode);
    }

    return PaymentsApiException(
      message: 'Request failed with status $statusCode',
      statusCode: statusCode,
    );
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return value.cast<String, dynamic>();
    throw const PaymentsApiException(
      message: 'Unexpected server response',
      statusCode: 500,
    );
  }

  List<dynamic> _asList(dynamic value) {
    if (value is List) return value;
    throw const PaymentsApiException(
      message: 'Unexpected server response',
      statusCode: 500,
    );
  }
}
