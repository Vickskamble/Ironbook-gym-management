class ExpenseModel {
  final String id;
  final String gymId;
  final String category;
  final String title;
  final double amount;
  final DateTime expenseDate;
  final String? paidBy;
  final String? receiptUrl;
  final String? note;
  final String createdBy;
  final DateTime createdAt;

  ExpenseModel({
    required this.id,
    required this.gymId,
    required this.category,
    required this.title,
    required this.amount,
    required this.expenseDate,
    this.paidBy,
    this.receiptUrl,
    this.note,
    required this.createdBy,
    required this.createdAt,
  });

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    return ExpenseModel(
      id: json['id'] as String,
      gymId: json['gym_id'] as String,
      category: json['category'] as String,
      title: json['title'] as String,
      amount: (json['amount'] as num).toDouble(),
      expenseDate: DateTime.parse(json['expense_date'] as String),
      paidBy: json['paid_by'] as String?,
      receiptUrl: json['receipt_url'] as String?,
      note: json['note'] as String?,
      createdBy: (json['created_by'] as String?) ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'gym_id': gymId,
      'category': category,
      'title': title,
      'amount': amount,
      'expense_date': expenseDate.toIso8601String(),
      'paid_by': paidBy,
      'receipt_url': receiptUrl,
      'note': note,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
    };
  }

  ExpenseModel copyWith({
    String? id,
    String? gymId,
    String? category,
    String? title,
    double? amount,
    DateTime? expenseDate,
    String? paidBy,
    String? receiptUrl,
    String? note,
    String? createdBy,
    DateTime? createdAt,
  }) {
    return ExpenseModel(
      id: id ?? this.id,
      gymId: gymId ?? this.gymId,
      category: category ?? this.category,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      expenseDate: expenseDate ?? this.expenseDate,
      paidBy: paidBy ?? this.paidBy,
      receiptUrl: receiptUrl ?? this.receiptUrl,
      note: note ?? this.note,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
