/// Mirrors Spring Data's default `Page<T>` JSON shape, which every
/// paginated backend endpoint returns as-is (no custom wrapper DTO exists
/// server-side).
class PageResponse<T> {
  const PageResponse({
    required this.content,
    required this.totalElements,
    required this.totalPages,
    required this.number,
    required this.size,
    required this.first,
    required this.last,
  });

  factory PageResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    return PageResponse(
      content: (json['content'] as List<dynamic>)
          .map((e) => fromJsonT(e as Map<String, dynamic>))
          .toList(),
      totalElements: json['totalElements'] as int,
      totalPages: json['totalPages'] as int,
      number: json['number'] as int,
      size: json['size'] as int,
      first: json['first'] as bool,
      last: json['last'] as bool,
    );
  }

  final List<T> content;
  final int totalElements;
  final int totalPages;
  final int number;
  final int size;
  final bool first;
  final bool last;
}
