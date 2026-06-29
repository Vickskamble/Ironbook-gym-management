class ProfileModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String role;
  final String? gymId;
  final String? avatarUrl;
  final String language;
  final bool isActive;
  final DateTime? lastLogin;
  final DateTime createdAt;
  final DateTime updatedAt;

  ProfileModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.gymId,
    this.avatarUrl,
    this.language = 'en',
    this.isActive = true,
    this.lastLogin,
    required this.createdAt,
    required this.updatedAt,
  });

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  bool get isSuperAdmin => role == 'superadmin';

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: (json['phone'] as String?) ?? '',
      role: json['role'] as String,
      gymId: json['gym_id'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      language: (json['language'] as String?) ?? 'en',
      isActive: (json['is_active'] as bool?) ?? true,
      lastLogin: json['last_login'] != null ? DateTime.parse(json['last_login'] as String) : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'gym_id': gymId,
      'avatar_url': avatarUrl,
      'language': language,
      'is_active': isActive,
      'last_login': lastLogin?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  ProfileModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? role,
    String? gymId,
    String? avatarUrl,
    String? language,
    bool? isActive,
    DateTime? lastLogin,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProfileModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      gymId: gymId ?? this.gymId,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      language: language ?? this.language,
      isActive: isActive ?? this.isActive,
      lastLogin: lastLogin ?? this.lastLogin,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
