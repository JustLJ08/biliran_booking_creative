/// Generic paginated result model that maps DRF's
/// {count, next, previous, results} response shape.
class PaginatedResult<T> {
  final int count;
  final String? next;
  final String? previous;
  final List<T> items;

  PaginatedResult({
    required this.count,
    this.next,
    this.previous,
    required this.items,
  });

  bool get hasMore => next != null;

  /// Parse a paginated API response.
  /// [fromJson] converts each item in the `results` array.
  factory PaginatedResult.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final results = (json['results'] as List<dynamic>?) ?? [];
    return PaginatedResult<T>(
      count: json['count'] ?? 0,
      next: json['next'],
      previous: json['previous'],
      items: results.map((item) => fromJson(item as Map<String, dynamic>)).toList(),
    );
  }
}
