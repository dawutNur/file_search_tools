class SearchResponseModel {
  final List<dynamic> files;
  final int total;
  final int currentPage;
  final int pages;
  final bool hasNext;
  final bool hasPrev;

  SearchResponseModel({
    required this.files,
    required this.total,
    required this.currentPage,
    required this.pages,
    required this.hasNext,
    required this.hasPrev,
  });

  factory SearchResponseModel.fromJson(Map<String, dynamic> json) {
    return SearchResponseModel(
      files: json['files'] ?? [],
      total: json['total'] ?? 0,
      currentPage: json['current_page'] ?? 1,
      pages: json['pages'] ?? 1,
      hasNext: json['has_next'] ?? false,
      hasPrev: json['has_prev'] ?? false,
    );
  }
}
