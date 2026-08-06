class AnnouncementResponse {
  const AnnouncementResponse({
    required this.id,
    required this.authorName,
    required this.title,
    required this.body,
    required this.status,
    required this.priority,
    required this.createdAt,
  });

  factory AnnouncementResponse.fromJson(Map<String, dynamic> json) {
    return AnnouncementResponse(
      id: json['id'] as String,
      authorName: json['authorName'] as String? ?? '',
      title: json['title'] as String,
      body: json['body'] as String,
      status: json['status'] as String,
      priority: json['priority'] as String? ?? 'NORMAL',
      createdAt: json['createdAt'] as String,
    );
  }

  final String id;
  final String authorName;
  final String title;
  final String body;
  final String status;
  final String priority;
  final String createdAt;
}
