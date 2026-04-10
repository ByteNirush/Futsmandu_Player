import 'package:dio/dio.dart';

import '../../../../core/config/api_config.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/error_handler.dart';
import '../models/payment_models.dart';

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

  final ApiClient _apiClient = ApiClient.instance;

  Future<KhaltiInitiationResult> initiateKhalti({
    required String bookingId,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiConfig.khaltiInitiateEndpoint,
        data: {'bookingId': bookingId},
      );
      return KhaltiInitiationResult.fromJson(_asMap(_unwrap(response.data)));
    } on DioException catch (error) {
      throw _toPaymentsApiException(error);
    }
  }

  Future<PaymentVerificationResult> verifyKhalti({
    required String pidx,
    required String bookingId,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiConfig.khaltiVerifyEndpoint,
        data: {
          'pidx': pidx,
          'bookingId': bookingId,
        },
      );
      return PaymentVerificationResult.fromJson(_asMap(_unwrap(response.data)));
    } on DioException catch (error) {
      throw _toPaymentsApiException(error);
    }
  }

  Future<EsewaInitiationResult> initiateEsewa({
    required String bookingId,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiConfig.esewaInitiateEndpoint,
        data: {'bookingId': bookingId},
      );
      return EsewaInitiationResult.fromJson(_asMap(_unwrap(response.data)));
    } on DioException catch (error) {
      throw _toPaymentsApiException(error);
    }
  }

  Future<PaymentVerificationResult> verifyEsewa({
    required String data,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiConfig.esewaVerifyEndpoint,
        data: {'data': data},
      );
      return PaymentVerificationResult.fromJson(_asMap(_unwrap(response.data)));
    } on DioException catch (error) {
      throw _toPaymentsApiException(error);
    }
  }

  Future<PaymentDetail> getPayment(String paymentId) async {
    try {
      final response =
          await _apiClient.get(ApiConfig.paymentDetailEndpoint(paymentId));
      return PaymentDetail.fromJson(_asMap(_unwrap(response.data)));
    } on DioException catch (error) {
      throw _toPaymentsApiException(error);
    }
  }

  Future<List<PaymentHistoryItem>> getPaymentHistory() async {
    try {
      final response = await _apiClient.get(ApiConfig.paymentHistoryEndpoint);
      final records = _asMapList(_unwrap(response.data));
      return records
          .map(PaymentHistoryItem.fromJson)
          .toList(growable: false);
    } on DioException catch (error) {
      throw _toPaymentsApiException(error);
    }
  }

  PaymentsApiException _toPaymentsApiException(DioException error) {
    final statusCode = error.response?.statusCode ?? 500;
    return PaymentsApiException(
      message: ErrorHandler.messageFor(error),
      statusCode: statusCode,
    );
  }

  dynamic _unwrap(dynamic body) {
    if (body is Map && body.containsKey('data')) {
      return body['data'];
    }
    return body;
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return value.cast<String, dynamic>();
    throw const PaymentsApiException(
      message: 'Unexpected server response',
      statusCode: 500,
    );
  }

  List<Map<String, dynamic>> _asMapList(dynamic value) {
    if (value is! List) return const <Map<String, dynamic>>[];
    return value.map(_asMap).toList(growable: false);
  }
}
