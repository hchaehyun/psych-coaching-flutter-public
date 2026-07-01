class AppNotification {
  const AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    required this.payload,
    required this.createdAt,
    this.targetType,
    this.targetId,
    this.dedupeKey,
    this.readAt,
    this.deletedAt,
    this.expiresAt,
  });

  final String id;
  final String userId;
  final String type;
  final String title;
  final String body;
  final String? targetType;
  final String? targetId;
  final Map<String, dynamic> payload;
  final String? dedupeKey;
  final DateTime createdAt;
  final DateTime? readAt;
  final DateTime? deletedAt;
  final DateTime? expiresAt;

  bool get isRead => readAt != null;

  AppNotification copyWith({
    String? id,
    String? userId,
    String? type,
    String? title,
    String? body,
    String? targetType,
    String? targetId,
    Map<String, dynamic>? payload,
    String? dedupeKey,
    DateTime? createdAt,
    DateTime? readAt,
    DateTime? deletedAt,
    DateTime? expiresAt,
  }) {
    return AppNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      targetType: targetType ?? this.targetType,
      targetId: targetId ?? this.targetId,
      payload: payload ?? this.payload,
      dedupeKey: dedupeKey ?? this.dedupeKey,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
      deletedAt: deletedAt ?? this.deletedAt,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }
}
