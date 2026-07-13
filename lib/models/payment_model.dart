class PaymentModel {
  final String id;
  final String gymId;
  final String memberId;
  final String? memberName;
  final String? planId;
  final String? planName;
  final double amount;
  final double discount;
  final double finalAmount;
  final DateTime paidAt;
  final String method;
  final String? transactionId;
  final String? note;
  final DateTime? nextDueDate;
  final String? createdBy;
  final DateTime createdAt;

  PaymentModel({
    required this.id,
    required this.gymId,
    required this.memberId,
    this.memberName,
    this.planId,
    this.planName,
    required this.amount,
    this.discount = 0.0,
    required this.finalAmount,
    required this.paidAt,
    required this.method,
    this.transactionId,
    this.note,
    this.nextDueDate,
    this.createdBy,
    required this.createdAt,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id'] as String,
      gymId: json['gym_id'] as String,
      memberId: json['member_id'] as String,
      memberName: json['member_name'] as String?,
      planId: json['plan_id'] as String?,
      planName: json['plan_name'] as String?,
      amount: (json['amount'] as num).toDouble(),
      discount: (json['discount'] as num?)?.toDouble() ?? 0.0,
      finalAmount: (json['final_amount'] as num).toDouble(),
      paidAt: DateTime.parse(json['paid_at'] as String),
      method: json['method'] as String,
      transactionId: json['transaction_id'] as String?,
      note: json['note'] as String?,
      nextDueDate: json['next_due_date'] != null
          ? DateTime.parse(json['next_due_date'] as String)
          : null,
      createdBy: json['created_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'gym_id': gymId,
      'member_id': memberId,
      'member_name': memberName,
      'plan_id': planId,
      'plan_name': planName,
      'amount': amount,
      'discount': discount,
      'final_amount': finalAmount,
      'paid_at': paidAt.toIso8601String(),
      'method': method,
      'transaction_id': transactionId,
      'note': note,
      'next_due_date': nextDueDate?.toIso8601String(),
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
    };
  }

  PaymentModel copyWith({
    String? id,
    String? gymId,
    String? memberId,
    String? memberName,
    String? planId,
    String? planName,
    double? amount,
    double? discount,
    double? finalAmount,
    DateTime? paidAt,
    String? method,
    String? transactionId,
    String? note,
    DateTime? nextDueDate,
    String? createdBy,
    DateTime? createdAt,
  }) {
    return PaymentModel(
      id: id ?? this.id,
      gymId: gymId ?? this.gymId,
      memberId: memberId ?? this.memberId,
      memberName: memberName ?? this.memberName,
      planId: planId ?? this.planId,
      planName: planName ?? this.planName,
      amount: amount ?? this.amount,
      discount: discount ?? this.discount,
      finalAmount: finalAmount ?? this.finalAmount,
      paidAt: paidAt ?? this.paidAt,
      method: method ?? this.method,
      transactionId: transactionId ?? this.transactionId,
      note: note ?? this.note,
      nextDueDate: nextDueDate ?? this.nextDueDate,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }

}
