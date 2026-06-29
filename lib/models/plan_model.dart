import 'dart:convert';
import 'package:flutter/material.dart';

class PlanModel {
  final String id;
  final String gymId;
  final String name;
  final String description;
  final int durationDays;
  final double price;
  final List<String> features;
  final bool isActive;
  final String color;
  final DateTime createdAt;
  final DateTime updatedAt;

  PlanModel({
    required this.id,
    required this.gymId,
    required this.name,
    this.description = '',
    required this.durationDays,
    required this.price,
    this.features = const [],
    this.isActive = true,
    this.color = '#6366F1',
    required this.createdAt,
    required this.updatedAt,
  });

  factory PlanModel.fromJson(Map<String, dynamic> json) {
    return PlanModel(
      id: json['id'] as String,
      gymId: json['gym_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      durationDays: json['duration_days'] as int,
      price: (json['price'] as num).toDouble(),
      features: _parseFeatures(json['features']),
      isActive: json['is_active'] as bool? ?? true,
      color: json['color'] as String? ?? '#6366F1',
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
      'duration_days': durationDays,
      'price': price,
      'features': features,
      'is_active': isActive,
      'color': color,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  PlanModel copyWith({
    String? id,
    String? gymId,
    String? name,
    String? description,
    int? durationDays,
    double? price,
    List<String>? features,
    bool? isActive,
    String? color,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PlanModel(
      id: id ?? this.id,
      gymId: gymId ?? this.gymId,
      name: name ?? this.name,
      description: description ?? this.description,
      durationDays: durationDays ?? this.durationDays,
      price: price ?? this.price,
      features: features ?? this.features,
      isActive: isActive ?? this.isActive,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static List<String> _parseFeatures(dynamic value) {
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    if (value is String && value.isNotEmpty) {
      try {
        final parsed = jsonDecode(value);
        if (parsed is List) {
          return parsed.map((e) => e.toString()).toList();
        }
      } catch (_) {}
    }
    return [];
  }

  // Get formatted price
  String get formattedPrice => '₹${price.toStringAsFixed(0)}';

  // Get duration label
  String get durationLabel => durationDays == 1 ? '1 day' : '$durationDays days';

  // Get currency symbol
  String get currency => '₹';

  // Check if plan is popular
  bool get isPopular => price >= 500 && price <= 2000;

  // Get status color
  Color get statusColor => isActive ? Colors.green : Colors.grey;

  // Get status label
  String get statusLabel => isActive ? 'Active' : 'Inactive';
}