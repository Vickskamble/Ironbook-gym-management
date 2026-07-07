class GymModel {
  final String id;
  final String name;
  final String address;
  final String phone;
  final String? gymType;
  final String ownerId;
  final String subscription;
  final DateTime? subscriptionExpiresAt;
  final bool isActive;
  final String? logoUrl;
  final String? website;
  final int? establishedYear;
  final int totalCapacity;
  final DateTime createdAt;
  final DateTime updatedAt;

  GymModel({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
    this.gymType,
    required this.ownerId,
    this.subscription = 'free',
    this.subscriptionExpiresAt,
    this.isActive = true,
    this.logoUrl,
    this.website,
    this.establishedYear,
    this.totalCapacity = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory GymModel.fromJson(Map<String, dynamic> json) {
    return GymModel(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String,
      phone: (json['phone'] as String?) ?? '',
      gymType: json['type'] as String?,
      ownerId: json['owner_id'] as String,
      subscription: (json['subscription'] as String?) ?? 'free',
      subscriptionExpiresAt: json['subscription_expires_at'] != null
          ? DateTime.parse(json['subscription_expires_at'] as String)
          : null,
      isActive: (json['is_active'] as bool?) ?? true,
      logoUrl: json['logo_url'] as String?,
      website: json['website'] as String?,
      establishedYear: json['established_year'] as int?,
      totalCapacity: (json['total_capacity'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'phone': phone,
      'type': gymType,
      'owner_id': ownerId,
      'subscription': subscription,
      'subscription_expires_at': subscriptionExpiresAt?.toIso8601String(),
      'is_active': isActive,
      'logo_url': logoUrl,
      'website': website,
      'established_year': establishedYear,
      'total_capacity': totalCapacity,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  GymModel copyWith({
    String? id,
    String? name,
    String? address,
    String? phone,
    String? gymType,
    String? ownerId,
    String? subscription,
    DateTime? subscriptionExpiresAt,
    bool? isActive,
    String? logoUrl,
    String? website,
    int? establishedYear,
    int? totalCapacity,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GymModel(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      gymType: gymType ?? this.gymType,
      ownerId: ownerId ?? this.ownerId,
      subscription: subscription ?? this.subscription,
      subscriptionExpiresAt: subscriptionExpiresAt ?? this.subscriptionExpiresAt,
      isActive: isActive ?? this.isActive,
      logoUrl: logoUrl ?? this.logoUrl,
      website: website ?? this.website,
      establishedYear: establishedYear ?? this.establishedYear,
      totalCapacity: totalCapacity ?? this.totalCapacity,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
