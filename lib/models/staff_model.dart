class StaffModel {
  final String id;
  final String gymId;
  final String name;
  final String phone;
  final String? email;
  final String role;
  final double salary;
  final DateTime joinDate;
  final String status;
  final String? profilePic;
  final String? specialization;
  final String? shift;
  final DateTime createdAt;
  final DateTime updatedAt;

  StaffModel({
    required this.id,
    required this.gymId,
    required this.name,
    required this.phone,
    this.email,
    required this.role,
    this.salary = 0.0,
    required this.joinDate,
    this.status = 'Active',
    this.profilePic,
    this.specialization,
    this.shift,
    required this.createdAt,
    required this.updatedAt,
  });

  factory StaffModel.fromJson(Map<String, dynamic> json) {
    return StaffModel(
      id: json['id'] as String,
      gymId: json['gym_id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String,
      email: json['email'] as String?,
      role: json['role'] as String,
      salary: (json['salary'] as num?)?.toDouble() ?? 0.0,
      joinDate: DateTime.parse(json['join_date'] as String),
      status: (json['status'] as String?) ?? 'Active',
      profilePic: json['profile_pic'] as String?,
      specialization: json['specialization'] as String?,
      shift: json['shift'] as String?,
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
      'role': role,
      'salary': salary,
      'join_date': joinDate.toIso8601String(),
      'status': status,
      'profile_pic': profilePic,
      'specialization': specialization,
      'shift': shift,
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
    double? salary,
    DateTime? joinDate,
    String? status,
    String? profilePic,
    String? specialization,
    String? shift,
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
      salary: salary ?? this.salary,
      joinDate: joinDate ?? this.joinDate,
      status: status ?? this.status,
      profilePic: profilePic ?? this.profilePic,
      specialization: specialization ?? this.specialization,
      shift: shift ?? this.shift,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
