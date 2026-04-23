class KhaltiInitiationResult {
  const KhaltiInitiationResult({
    required this.paymentUrl,
    required this.pidx,
  });

  final String paymentUrl;
  final String pidx;

  factory KhaltiInitiationResult.fromJson(Map<String, dynamic> json) {
    return KhaltiInitiationResult(
      paymentUrl: (json['payment_url'] ?? json['paymentUrl'] ?? '').toString(),
      pidx: (json['pidx'] ?? '').toString(),
    );
  }
}

class EsewaInitiationResult {
  const EsewaInitiationResult({
    required this.raw,
  });

  final Map<String, dynamic> raw;

  factory EsewaInitiationResult.fromJson(Map<String, dynamic> json) {
    return EsewaInitiationResult(raw: json);
  }
}

class PaymentVerificationResult {
  const PaymentVerificationResult({required this.raw});

  final Map<String, dynamic> raw;

  factory PaymentVerificationResult.fromJson(Map<String, dynamic> json) {
    return PaymentVerificationResult(raw: json);
  }

  Map<String, dynamic> toMap() => raw;
}

class PaymentBookingInfo {
  const PaymentBookingInfo({
    required this.bookingDate,
    required this.startTime,
    required this.courtName,
    required this.venueName,
  });

  final String bookingDate;
  final String startTime;
  final String courtName;
  final String venueName;

  factory PaymentBookingInfo.fromJson(Map<String, dynamic> json) {
    final court = json['court'] is Map
        ? (json['court'] as Map).cast<String, dynamic>()
        : const <String, dynamic>{};
    final venue = court['venue'] is Map
        ? (court['venue'] as Map).cast<String, dynamic>()
        : const <String, dynamic>{};

    return PaymentBookingInfo(
      bookingDate: (json['booking_date'] ?? '').toString(),
      startTime: (json['start_time'] ?? '').toString(),
      courtName: (court['name'] ?? '').toString(),
      venueName: (venue['name'] ?? '').toString(),
    );
  }
}

class PaymentHistoryItem {
  const PaymentHistoryItem({
    required this.id,
    required this.bookingId,
    required this.amount,
    required this.displayAmount,
    required this.gateway,
    required this.status,
    required this.initiatedAt,
    required this.completedAt,
    required this.booking,
  });

  final String id;
  final String bookingId;
  final int amount;
  final String displayAmount;
  final String gateway;
  final String status;
  final String initiatedAt;
  final String completedAt;
  final PaymentBookingInfo booking;

  factory PaymentHistoryItem.fromJson(Map<String, dynamic> json) {
    return PaymentHistoryItem(
      id: (json['id'] ?? '').toString(),
      bookingId: (json['booking_id'] ?? '').toString(),
      amount: _toInt(json['amount']),
      displayAmount: (json['displayAmount'] ?? '').toString(),
      gateway: (json['gateway'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      initiatedAt: (json['initiated_at'] ?? '').toString(),
      completedAt: (json['completed_at'] ?? '').toString(),
      booking: PaymentBookingInfo.fromJson(
        json['booking'] is Map
            ? (json['booking'] as Map).cast<String, dynamic>()
            : const <String, dynamic>{},
      ),
    );
  }
}

class PaymentDetail {
  const PaymentDetail({
    required this.id,
    required this.bookingId,
    required this.playerId,
    required this.amount,
    required this.displayAmount,
    required this.gateway,
    required this.status,
    required this.gatewayTransactionId,
    required this.initiatedAt,
    required this.completedAt,
    required this.refundInitiatedAt,
    required this.refundCompletedAt,
  });

  final String id;
  final String bookingId;
  final String playerId;
  final int amount;
  final String displayAmount;
  final String gateway;
  final String status;
  final String gatewayTransactionId;
  final String initiatedAt;
  final String completedAt;
  final String refundInitiatedAt;
  final String refundCompletedAt;

  factory PaymentDetail.fromJson(Map<String, dynamic> json) {
    return PaymentDetail(
      id: (json['id'] ?? '').toString(),
      bookingId: (json['booking_id'] ?? '').toString(),
      playerId: (json['player_id'] ?? '').toString(),
      amount: _toInt(json['amount']),
      displayAmount: (json['displayAmount'] ?? '').toString(),
      gateway: (json['gateway'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      gatewayTransactionId: (json['gateway_tx_id'] ?? '').toString(),
      initiatedAt: (json['initiated_at'] ?? '').toString(),
      completedAt: (json['completed_at'] ?? '').toString(),
      refundInitiatedAt: (json['refund_initiated_at'] ?? '').toString(),
      refundCompletedAt: (json['refund_completed_at'] ?? '').toString(),
    );
  }
}

int _toInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}
