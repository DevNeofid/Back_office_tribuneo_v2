class PaginatedResult<T> {
  final List<T> items;
  final int total;

  const PaginatedResult({
    required this.items,
    required this.total,
  });
}
