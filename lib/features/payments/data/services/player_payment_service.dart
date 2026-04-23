import 'package:dio/dio.dart';

import '../../../../core/config/api_config.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/error_handler.dart';
import '../models/player_payment_models.dart';

class PaymentApiException implements Exception {
  const PaymentApiException({required this.message, required this.statusCode});

  final String message;
  final int statusCode;

  @override
  String toString() => 'PaymentApiException($statusCode): $message';
}

class PlayerPaymentService {
  PlayerPaymentService._internal();

  static final PlayerPaymentService instance = PlayerPaymentService._internal();

  final ApiClient _client = ApiClient.instance;

  Future<KhaltiInitiateResponse> initiateKhaltiPayment({
    required int amount,
    required String productName,
    String? productIdentity,
    String? returnUrl,
  }) async {
    try {
      final response = await _client.post(
        '${ApiConfig.baseUrl}/payments/khalti-initiate',
        data: {
          'amount': amount,
          'productName': productName,
          'productIdentity': productIdentity,
          'returnUrl': returnUrl,
        },
      );

      return KhaltiInitiateResponse.fromMap(_asMap(_unwrap(response.data)));
    } on DioException catch (error) {
      throw _toPaymentApiExceptionFromDio(error);
    }
  }

  Future<PaymentVerifyResult> verifyKhaltiPayment({
    required String pidx,
    required String transactionId,
  }) async {
    try {
      final response = await _client.post(
        '${ApiConfig.baseUrl}/payments/khalti-verify',
        data: {
          'pidx': pidx,
          'transactionId': transactionId,
        },
      );

      return PaymentVerifyResult.fromMap(_asMap(_unwrap(response.data)));
    } on DioException catch (error) {
      throw _toPaymentApiExceptionFromDio(error);
    }
  }

  Future<ESewaInitiateResponse> initiateESewaPayment({
    required int amount,
    required String productName,
    String? productIdentity,
    String? returnUrl,
  }) async {
    try {
      final response = await _client.post(
        '${ApiConfig.baseUrl}/payments/esewa-initiate',
        data: {
          'amount': amount,
          'productName': productName,
          'productIdentity': productIdentity,
          'returnUrl': returnUrl,
        },
      );

      return ESewaInitiateResponse.fromMap(_asMap(_unwrap(response.data)));
    } on DioException catch (error) {
      throw _toPaymentApiExceptionFromDio(error);
    }
  }

  Future<PaymentVerifyResult> verifyESewaPayment({
    required String referenceId,
    required String decodedProductData,
  }) async {
    try {
      final response = await _client.post(
        '${ApiConfig.baseUrl}/payments/esewa-verify',
        data: {
          'referenceId': referenceId,
          'decodedProductData': decodedProductData,
        },
      );

      return PaymentVerifyResult.fromMap(_asMap(_unwrap(response.data)));
    } on DioException catch (error) {
      throw _toPaymentApiExceptionFromDio(error);
    }
  }

  Future<Payment> getPaymentDetail(String paymentId) async {
    try {
      final response = await _client.get(
        '${ApiConfig.baseUrl}/payments/$paymentId',
      );

      return Payment.fromMap(_asMap(_unwrap(response.data)));
    } on DioException catch (error) {
      throw _toPaymentApiExceptionFromDio(error);
    }
  }

  Future<List<Payment>> getPaymentHistory() async {
    try {
      final response = await _client.get(
        '${ApiConfig.baseUrl}/payments/history',
      );

      final records = _asMapList(_unwrap(response.data));
      return records.map((raw) => Payment.fromMap(raw)).toList(growable: false);
    } on DioException catch (error) {
      throw _toPaymentApiExceptionFromDio(error);
    }
  }

  Future<Map<String, dynamic>> getPaymentHistoryLegacy() async {
    final history = await getPaymentHistory();
    return {
      'items': history.map((item) => item.toMap()).toList(),
    };
  }

  dynamic _unwrap(dynamic body) {
    if (body is Map && body.containsKey('data')) {
      return body['data'];
    }
    return body;
  }

  PaymentApiException _toPaymentApiExceptionFromDio(DioException error) {
    return PaymentApiException(
      message: ErrorHandler.messageFor(error),
      statusCode: error.response?.statusCode ?? 500,
    );
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map) return value.cast<String, dynamic>();
    return const <String, dynamic>{};
  }

  List<Map<String, dynamic>> _asMapList(dynamic value) {
    if (value is! List) return const <Map<String, dynamic>>[];
    return value
        .whereType<Map>()
        .map((item) => item.cast<String, dynamic>())
        .toList(growable: false);
  }
}
