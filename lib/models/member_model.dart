import 'package:flutter/material.dart';

class MemberModel {
  final String id;
  final String gymId;
  final String name;
  final String phone;
  final String? email;
  final String? gender;
  final int? age;
  final String? address;
  final String? planId;
  final String? planName;
  final DateTime joinDate;
  final DateTime? membershipStart;
  final DateTime? membershipEnd;
  final String status;
  final String? profilePic;
  final String? emergencyContact;
  final String? bloodGroup;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  MemberModel({
    required this.id,
    required this.gymId,
    required this.name,
    required this.phone,
    this.email,
    this.gender,
    this.age,
    this.address,
    this.planId,
    this.planName,
    required this.joinDate,
    this.membershipStart,
    this.membershipEnd,
    this.status = 'Active',
    this.profilePic,
    this.emergencyContact,
    this.bloodGroup,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  Color get statusColor {
    switch (status) {
      case 'Active':
        return Colors.green;
      case 'Expired':
        return Colors.red;
      case 'Paused':
        return Colors.amber;
      case 'Deleted':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  bool get isExpired {
    if (membershipEnd == null) return false;
    return DateTime.now().isAfter(membershipEnd!);
  }

  int get daysUntilExpiry {
    if (membershipEnd == null) return -1;
    return membershipEnd!.difference(DateTime.now()).inDays;
  }

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  factory MemberModel.fromJson(Map<String, dynamic> json) {
    return MemberModel(
      id: json['id'] as String,
      gymId: json['gym_id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String,
      email: json['email'] as String?,
      gender: json['gender'] as String?,
      age: (json['age'] as num?)?.toInt(),
      address: json['address'] as String?,
      planId: json['plan_id'] as String?,
      planName: json['plan_name'] as String?,
      joinDate: DateTime.parse(json['join_date'] as String),
      membershipStart: json['membership_start'] != null
          ? DateTime.parse(json['membership_start'] as String)
          : null,
      membershipEnd: json['membership_end'] != null
          ? DateTime.parse(json['membership_end'] as String)
          : null,
      status: (json['status'] as String?) ?? 'Active',
      profilePic: json['profile_pic'] as String?,
      emergencyContact: json['emergency_contact'] as String?,
      bloodGroup: json['blood_group'] as String?,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'gym_id': gymId,
      'name': name,
      'phone': phone,
      'email': email,
      'gender': gender,
      'age': age,
      'address': address,
      'plan_id': planId,
      'plan_name': planName,
      'join_date': joinDate.toIso8601String(),
      'membership_start': membershipStart?.toIso8601String(),
      'membership_end': membershipEnd?.toIso8601String(),
      'status': status,
      'profile_pic': profilePic,
      'emergency_contact': emergencyContact,
      'blood_group': bloodGroup,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  MemberModel copyWith({
    String? id,
    String? gymId,
    String? name,
    String? phone,
    String? email,
    String? gender,
    int? age,
    String? address,
    String? planId,
    String? planName,
    DateTime? joinDate,
    DateTime? membershipStart,
    DateTime? membershipEnd,
    String? status,
    String? profilePic,
    String? emergencyContact,
    String? bloodGroup,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MemberModel(
      id: id ?? this.id,
      gymId: gymId ?? this.gymId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      gender: gender ?? this.gender,
      age: age ?? this.age,
      address: address ?? this.address,
      planId: planId ?? this.planId,
      planName: planName ?? this.planName,
      joinDate: joinDate ?? this.joinDate,
      membershipStart: membershipStart ?? this.membershipStart,
      membershipEnd: membershipEnd ?? this.membershipEnd,
      status: status ?? this.status,
      profilePic: profilePic ?? this.profilePic,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
