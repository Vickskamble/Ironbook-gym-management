class AttendanceModel {
  final String id;
  final String gymId;
  final String memberId;
  final String? memberName;
  final String? memberPhone;
  final DateTime checkIn;
  final DateTime? checkOut;
  final int? durationMinutes;
  final String markedBy;
  final DateTime createdAt;

  AttendanceModel({
    required this.id,
    required this.gymId,
    required this.memberId,
    this.memberName,
    this.memberPhone,
    required this.checkIn,
    this.checkOut,
    this.durationMinutes,
    required this.markedBy,
    required this.createdAt,
  });

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    return AttendanceModel(
      id: json['id'] as String,
      gymId: json['gym_id'] as String,
      memberId: json['member_id'] as String,
      memberName: json['member_name'] as String?,
      memberPhone: json['member_phone'] as String?,
      checkIn: DateTime.parse(json['check_in'] as String),
      checkOut: json['check_out'] != null
          ? DateTime.parse(json['check_out'] as String)
          : null,
      durationMinutes: (json['duration_minutes'] as num?)?.toInt(),
      markedBy: (json['marked_by'] as String?) ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'gym_id': gymId,
      'member_id': memberId,
      'member_name': memberName,
      'member_phone': memberPhone,
      'check_in': checkIn.toIso8601String(),
      'check_out': checkOut?.toIso8601String(),
      'duration_minutes': durationMinutes,
      'marked_by': markedBy,
      'created_at': createdAt.toIso8601String(),
    };
  }

  AttendanceModel copyWith({
    String? id,
    String? gymId,
    String? memberId,
    String? memberName,
    String? memberPhone,
    DateTime? checkIn,
    DateTime? checkOut,
    int? durationMinutes,
    String? markedBy,
    DateTime? createdAt,
  }) {
    return AttendanceModel(
      id: id ?? this.id,
      gymId: gymId ?? this.gymId,
      memberId: memberId ?? this.memberId,
      memberName: memberName ?? this.memberName,
      memberPhone: memberPhone ?? this.memberPhone,
      checkIn: checkIn ?? this.checkIn,
      checkOut: checkOut ?? this.checkOut,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      markedBy: markedBy ?? this.markedBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
