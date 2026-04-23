class Payment {
  const Payment({
    required this.id,
    required this.type,
    required this.amount,
    required this.status,
    required this.createdAt,
    this.verificationId,
    this.description,
  });

  final String id;
  final String type;
  final int amount;
  final String status;
  final String createdAt;
  final String? verificationId;
  final String? description;

  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      id: _string(map['id']),
      type: _string(map['type']),
      amount: _toInt(map['amount']),
      status: _string(map['status']),
      createdAt: _string(map['createdAt']),
      verificationId: _stringOrNull(map['verificationId']),
      description: _stringOrNull(map['description']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'amount': amount,
      'status': status,
      'createdAt': createdAt,
      'verificationId': verificationId,
      'description': description,
    };
  }
}

class KhaltiInitiateRequest {
  const KhaltiInitiateRequest({
    required this.amount,
    required this.productName,
    this.productIdentity,
    this.returnUrl,
  });

  final int amount;
  final String productName;
  final String? productIdentity;
  final String? returnUrl;

  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
      'productName': productName,
      'productIdentity': productIdentity,
      'returnUrl': returnUrl,
    };
  }
}

class KhaltiInitiateResponse {
  const KhaltiInitiateResponse({
    required this.token,
    required this.pidx,
  });

  final String token;
  final String pidx;

  factory KhaltiInitiateResponse.fromMap(Map<String, dynamic> map) {
    return KhaltiInitiateResponse(
      token: _string(map['token']),
      pidx: _string(map['pidx']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'token': token,
      'pidx': pidx,
    };
  }
}

class KhaltiVerifyRequest {
  const KhaltiVerifyRequest({
    required this.pidx,
    required this.transactionId,
  });

  final String pidx;
  final String transactionId;

  Map<String, dynamic> toMap() {
    return {
      'pidx': pidx,
      'transactionId': transactionId,
    };
  }
}

class ESewaInitiateRequest {
  const ESewaInitiateRequest({
    required this.amount,
    required this.productName,
    this.productIdentity,
    this.returnUrl,
  });

  final int amount;
  final String productName;
  final String? productIdentity;
  final String? returnUrl;

  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
      'productName': productName,
      'productIdentity': productIdentity,
      'returnUrl': returnUrl,
    };
  }
}

class ESewaInitiateResponse {
  const ESewaInitiateResponse({
    required this.referenceId,
    this.formData,
  });

  final String referenceId;
  final Map<String, dynamic>? formData;

  factory ESewaInitiateResponse.fromMap(Map<String, dynamic> map) {
    return ESewaInitiateResponse(
      referenceId: _string(map['referenceId']),
      formData: _asMap(map['formData']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'referenceId': referenceId,
      'formData': formData,
    };
  }
}

class ESewaVerifyRequest {
  const ESewaVerifyRequest({
    required this.referenceId,
    required this.decodedProductData,
  });

  final String referenceId;
  final String decodedProductData;

  Map<String, dynamic> toMap() {
    return {
      'referenceId': referenceId,
      'decodedProductData': decodedProductData,
    };
  }
}

class PaymentVerifyResult {
  const PaymentVerifyResult({
    required this.paymentId,
    required this.status,
    required this.message,
  });

  final String paymentId;
  final String status;
  final String message;

  factory PaymentVerifyResult.fromMap(Map<String, dynamic> map) {
    return PaymentVerifyResult(
      paymentId: _string(map['paymentId']),
      status: _string(map['status']),
      message: _string(map['message']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'paymentId': paymentId,
      'status': status,
      'message': message,
    };
  }
}

String _string(dynamic value) {
  if (value is String) return value;
  return '';
}

String? _stringOrNull(dynamic value) {
  if (value is String) return value;
  return null;
}

int _toInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map) return value.cast<String, dynamic>();
  return const <String, dynamic>{};
}
