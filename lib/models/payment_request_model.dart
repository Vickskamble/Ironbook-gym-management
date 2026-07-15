class PaymentRequest {
  final String id;
  final String gymId;
  final String planType;
  final String planName;
  final double amount;
  final String status;
  final String? createdBy;
  final DateTime createdAt;
  final String? razorpayOrderId;
  final String? razorpayPaymentId;
  final DateTime? updatedAt;
  final Map<String, dynamic>? paymentMetadata;

  PaymentRequest({
    required this.id,
    required this.gymId,
    required this.planType,
    required this.planName,
    required this.amount,
    required this.status,
    this.createdBy,
    required this.createdAt,
    this.razorpayOrderId,
    this.razorpayPaymentId,
    this.updatedAt,
    this.paymentMetadata,
  });

  factory PaymentRequest.fromJson(Map<String, dynamic> json) {
    return PaymentRequest(
      id: json['id'] as String,
      gymId: json['gym_id'] as String,
      planType: json['plan_type'] as String,
      planName: json['plan_name'] as String,
      amount: (json['amount'] as num).toDouble(),
      status: json['status'] as String,
      createdBy: json['created_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      razorpayOrderId: json['razorpay_order_id'] as String?,
      razorpayPaymentId: json['razorpay_payment_id'] as String?,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      paymentMetadata: json['payment_metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    final map = {
      'id': id,
      'gym_id': gymId,
      'plan_type': planType,
      'plan_name': planName,
      'amount': amount,
      'status': status,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'razorpay_order_id': razorpayOrderId,
      'razorpay_payment_id': razorpayPaymentId,
      'updated_at': updatedAt?.toIso8601String(),
      'payment_metadata': paymentMetadata,
    };
    return map..removeWhere((key, value) => value == null);
  }

  PaymentRequest copyWith({
    String? id,
    String? gymId,
    String? planType,
    String? planName,
    double? amount,
    String? status,
    String? createdBy,
    DateTime? createdAt,
    String? razorpayOrderId,
    String? razorpayPaymentId,
    DateTime? updatedAt,
    Map<String, dynamic>? paymentMetadata,
  }) {
    return PaymentRequest(
      id: id ?? this.id,
      gymId: gymId ?? this.gymId,
      planType: planType ?? this.planType,
      planName: planName ?? this.planName,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      razorpayOrderId: razorpayOrderId ?? this.razorpayOrderId,
      razorpayPaymentId: razorpayPaymentId ?? this.razorpayPaymentId,
      updatedAt: updatedAt ?? this.updatedAt,
      paymentMetadata: paymentMetadata ?? this.paymentMetadata,
    );
  }
}