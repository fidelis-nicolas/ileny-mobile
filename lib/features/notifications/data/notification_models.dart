class NotificationResponse {
  const NotificationResponse({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.isRead,
    this.readAt,
    required this.createdAt,
  });

  factory NotificationResponse.fromJson(Map<String, dynamic> json) {
    return NotificationResponse(
      id: json['id'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      isRead: json['isRead'] as bool? ?? false,
      readAt: json['readAt'] as String?,
      createdAt: json['createdAt'] as String,
    );
  }

  final String id;
  final String type;
  final String title;
  final String message;
  final bool isRead;
  final String? readAt;
  final String createdAt;
}
