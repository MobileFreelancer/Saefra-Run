import 'package:saefra_run/core/models/community_route_model.dart';
import 'package:saefra_run/core/models/review_model.dart';

class RouteReviewStatistics {
  const RouteReviewStatistics({
    this.totalReviews = 0,
    this.averageRating = 0,
    this.ratingDistribution = const {},
  });

  final int totalReviews;
  final double averageRating;
  final Map<int, double> ratingDistribution;

  factory RouteReviewStatistics.fromJson(Map<String, dynamic> json) {
    final distribution = <int, double>{};
    final percentages = json['rating_percentages'];
    if (percentages is Map) {
      for (final star in [5, 4, 3, 2, 1]) {
        final raw = percentages['$star'] ?? percentages[star];
        final percent = _toDouble(raw);
        distribution[star] = (percent / 100).clamp(0.0, 1.0);
      }
    }

    return RouteReviewStatistics(
      totalReviews: _toInt(json['total_reviews'] ?? json['review_count']),
      averageRating: _toDouble(json['average_rating'] ?? json['rating']),
      ratingDistribution: distribution,
    );
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  static int _toInt(dynamic value) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}

class RouteReviewListResult {
  const RouteReviewListResult({
    this.route,
    this.statistics,
    required this.reviews,
    this.photos = const [],
    this.currentPage = 1,
    this.hasMore = false,
    this.hasMorePhotos = false,
  });

  final CommunityRouteModel? route;
  final RouteReviewStatistics? statistics;
  final List<ReviewModel> reviews;
  final List<String> photos;
  final int currentPage;
  final bool hasMore;
  final bool hasMorePhotos;

  factory RouteReviewListResult.fromPayload(
      Map<String, dynamic> payload, {
        required int page,
        required int perPage,
      }) {
    final routeRaw = payload['route'];
    final statisticsRaw = payload['statistics'];
    final reviewsRaw = payload['reviews'];
    final photosRaw = payload['photos'];

    return RouteReviewListResult(
      route: routeRaw is Map
          ? CommunityRouteModel.fromJson(
        Map<String, dynamic>.from(routeRaw),
      )
          : null,
      statistics: statisticsRaw is Map
          ? RouteReviewStatistics.fromJson(
        Map<String, dynamic>.from(statisticsRaw),
      )
          : null,
      reviews: _parseReviews(reviewsRaw),
      photos: _parsePhotos(photosRaw),
      currentPage: _toInt(
        (reviewsRaw as Map?)?['currentPage'] ??
            (reviewsRaw as Map?)?['current_page'],
      ) ==
          0
          ? page
          : _toInt(
        (reviewsRaw as Map)['currentPage'] ??
            reviewsRaw['current_page'],
      ),
      hasMore: _hasMorePages(
        reviewsRaw is Map ? Map<String, dynamic>.from(reviewsRaw) : {},
        page: page,
        perPage: perPage,
        itemCount: _parseReviews(reviewsRaw).length,
      ),
      hasMorePhotos: _hasMorePages(
        photosRaw is Map ? Map<String, dynamic>.from(photosRaw) : {},
        page: 1,
        perPage: perPage,
        itemCount: _parsePhotos(photosRaw).length,
      ),
    );
  }

  static bool _hasMorePages(
    Map<String, dynamic> pagination, {
    required int page,
    required int perPage,
    required int itemCount,
  }) {
    final currentPage = _toInt(
      pagination['currentPage'] ?? pagination['current_page'] ?? page,
    );
    final activePage = currentPage > 0 ? currentPage : page;
    final totalPage = _toInt(
      pagination['totalPage'] ??
          pagination['total_page'] ??
          pagination['last_page'],
    );
    if (totalPage > 0) return activePage < totalPage;

    final totalRecords = _toInt(
      pagination['totalRecords'] ??
          pagination['total_records'] ??
          pagination['total'],
    );
    if (totalRecords > 0) return activePage * perPage < totalRecords;

    return itemCount >= perPage;
  }

  static List<ReviewModel> _parseReviews(dynamic raw) {
    return _unwrapList(raw)
        .map(
          (item) => ReviewModel.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  static List<String> _parsePhotos(dynamic raw) {
    return _unwrapList(raw)
        .map(_photoUrlFromItem)
        .where((url) => url.isNotEmpty)
        .toList();
  }

  static String _photoUrlFromItem(dynamic item) {
    if (item is String) return item.trim();

    if (item is Map) {
      final map = Map<String, dynamic>.from(item);

      final url = map['image_url'] ??
          map['url'] ??
          map['image'] ??
          map['photo'] ??
          map['path'];

      return url?.toString().trim() ?? '';
    }

    return '';
  }

  static List<dynamic> _unwrapList(dynamic raw) {
    if (raw is List) return raw;
    if (raw is Map) {
      final data = raw['data'];
      if (data is List) return data;
    }
    return const [];
  }

  static int _toInt(dynamic value) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
