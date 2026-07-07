class InventoryItem {
  final String id;
  final String gymId;
  final String name;
  final String? description;
  final String category;
  final int quantity;
  final int lowStockThreshold;
  final double unitPrice;
  final double? sellingPrice;
  final String? supplier;
  final String? unit;
  final DateTime createdAt;
  final DateTime updatedAt;

  InventoryItem({
    required this.id,
    required this.gymId,
    required this.name,
    this.description,
    this.category = 'Supplements',
    this.quantity = 0,
    this.lowStockThreshold = 5,
    this.unitPrice = 0,
    this.sellingPrice,
    this.supplier,
    this.unit = 'pcs',
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isLowStock => quantity <= lowStockThreshold;

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    return InventoryItem(
      id: json['id'] as String,
      gymId: json['gym_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      category: (json['category'] as String?) ?? 'Supplements',
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      lowStockThreshold: (json['low_stock_threshold'] as num?)?.toInt() ?? 5,
      unitPrice: (json['unit_price'] as num?)?.toDouble() ?? 0,
      sellingPrice: (json['selling_price'] as num?)?.toDouble(),
      supplier: json['supplier'] as String?,
      unit: (json['unit'] as String?) ?? 'pcs',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'gym_id': gymId,
      'name': name,
      'description': description,
      'category': category,
      'quantity': quantity,
      'low_stock_threshold': lowStockThreshold,
      'unit_price': unitPrice,
      'selling_price': sellingPrice,
      'supplier': supplier,
      'unit': unit,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  InventoryItem copyWith({
    String? id,
    String? gymId,
    String? name,
    String? description,
    String? category,
    int? quantity,
    int? lowStockThreshold,
    double? unitPrice,
    double? sellingPrice,
    String? supplier,
    String? unit,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return InventoryItem(
      id: id ?? this.id,
      gymId: gymId ?? this.gymId,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      quantity: quantity ?? this.quantity,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      unitPrice: unitPrice ?? this.unitPrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      supplier: supplier ?? this.supplier,
      unit: unit ?? this.unit,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class InventorySale {
  final String id;
  final String gymId;
  final String itemId;
  final String itemName;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final String? memberName;
  final String? memberId;
  final String? soldBy;
  final DateTime soldAt;
  final String? note;
  final DateTime createdAt;

  InventorySale({
    required this.id,
    required this.gymId,
    required this.itemId,
    required this.itemName,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    this.memberName,
    this.memberId,
    this.soldBy,
    required this.soldAt,
    this.note,
    required this.createdAt,
  });

  factory InventorySale.fromJson(Map<String, dynamic> json) {
    return InventorySale(
      id: json['id'] as String,
      gymId: json['gym_id'] as String,
      itemId: json['item_id'] as String,
      itemName: (json['item_name'] as String?) ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      unitPrice: (json['unit_price'] as num?)?.toDouble() ?? 0,
      totalPrice: (json['total_price'] as num?)?.toDouble() ?? 0,
      memberName: json['member_name'] as String?,
      memberId: json['member_id'] as String?,
      soldBy: json['sold_by'] as String?,
      soldAt: DateTime.parse(json['sold_at'] as String),
      note: json['note'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
