import 'package:saefra_run/core/models/review_model.dart';

class RouteReviewListResult {
  const RouteReviewListResult({
    required this.reviews,
    this.currentPage = 1,
    this.hasMore = false,
  });

  final List<ReviewModel> reviews;
  final int currentPage;
  final bool hasMore;

  factory RouteReviewListResult.fromPayload(
    Map<String, dynamic> payload, {
    required int page,
    required int perPage,
  }) {
    final reviewsRaw = payload['reviews'] ??
        payload['route_reviews'] ??
        payload['data'] ??
        payload;

    final reviews = _parseReviews(reviewsRaw);
    final paginationSource = reviewsRaw is Map
        ? Map<String, dynamic>.from(reviewsRaw)
        : payload;

    final currentPage = _toInt(
      paginationSource['currentPage'] ??
          paginationSource['current_page'] ??
          page,
    );
    final totalPage = _toInt(
      paginationSource['totalPage'] ??
          paginationSource['total_page'] ??
          paginationSource['last_page'],
    );
    final totalRecords = _toInt(
      paginationSource['totalRecords'] ??
          paginationSource['total_records'] ??
          paginationSource['total'],
    );

    final hasMore = totalPage > 0
        ? currentPage < totalPage
        : (totalRecords > 0
            ? currentPage * perPage < totalRecords
            : reviews.length >= perPage);

    return RouteReviewListResult(
      reviews: reviews,
      currentPage: currentPage > 0 ? currentPage : page,
      hasMore: hasMore,
    );
  }

  static List<ReviewModel> _parseReviews(dynamic raw) {
    final items = _unwrapList(raw);
    return items
        .map(
          (item) => ReviewModel.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  static List<dynamic> _unwrapList(dynamic raw) {
    if (raw is List) return raw;
    if (raw is Map) {
      final data = raw['data'];
      if (data is List) return data;
      final reviews = raw['reviews'];
      if (reviews is List) return reviews;
    }
    return const [];
  }

  static int _toInt(dynamic value) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
