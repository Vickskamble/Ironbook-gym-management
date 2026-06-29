class NotificationModel {
  final String id;
  final String gymId;
  final String title;
  final String body;
  final String type;
  final bool isRead;
  final String? memberId;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.gymId,
    required this.title,
    required this.body,
    required this.type,
    this.isRead = false,
    this.memberId,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      gymId: json['gym_id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      type: json['type'] as String,
      isRead: (json['is_read'] as bool?) ?? false,
      memberId: json['member_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'gym_id': gymId,
      'title': title,
      'body': body,
      'type': type,
      'is_read': isRead,
      'member_id': memberId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  NotificationModel copyWith({
    String? id,
    String? gymId,
    String? title,
    String? body,
    String? type,
    bool? isRead,
    String? memberId,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      gymId: gymId ?? this.gymId,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      memberId: memberId ?? this.memberId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
