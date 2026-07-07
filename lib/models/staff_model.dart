import 'profile_model.dart';

class StaffModel {
  final String id;
  final String gymId;
  final String name;
  final String phone;
  final String? email;
  final String role;
  final String status;
  final String? profilePic;
  final DateTime createdAt;
  final DateTime updatedAt;

  StaffModel({
    required this.id,
    required this.gymId,
    required this.name,
    required this.phone,
    this.email,
    required this.role,
    this.status = 'Active',
    this.profilePic,
    required this.createdAt,
    required this.updatedAt,
  });

  factory StaffModel.fromJson(Map<String, dynamic> json) {
    return StaffModel(
      id: json['id'] as String,
      gymId: json['gym_id'] as String,
      name: json['name'] as String,
      phone: (json['phone'] as String?) ?? '',
      email: json['email'] as String?,
      role: json['role'] as String,
      status: (json['is_active'] as bool?) == true ? 'Active' : 'Inactive',
      profilePic: json['avatar_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  factory StaffModel.fromProfile(ProfileModel profile) {
    return StaffModel(
      id: profile.id,
      gymId: profile.gymId ?? '',
      name: profile.name,
      phone: profile.phone,
      email: profile.email,
      role: profile.role,
      status: profile.isActive ? 'Active' : 'Inactive',
      profilePic: profile.avatarUrl,
      createdAt: profile.createdAt,
      updatedAt: profile.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'gym_id': gymId,
      'name': name,
      'phone': phone,
      'email': email,
      'role': role,
      'is_active': status != 'Inactive',
      'avatar_url': profilePic,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  StaffModel copyWith({
    String? id,
    String? gymId,
    String? name,
    String? phone,
    String? email,
    String? role,
    String? status,
    String? profilePic,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return StaffModel(
      id: id ?? this.id,
      gymId: gymId ?? this.gymId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      role: role ?? this.role,
      status: status ?? this.status,
      profilePic: profilePic ?? this.profilePic,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
