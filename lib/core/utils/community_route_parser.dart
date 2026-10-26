import 'package:saefra_run/core/models/community_route_model.dart';

/// Shared parsing for community route API payloads.
class CommunityRouteParser {
  CommunityRouteParser._();

  static List<CommunityRouteModel> parseRoutes(dynamic raw) {
    return unwrapItems(raw)
        .map(
          (item) => CommunityRouteModel.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  static List<dynamic> unwrapItems(dynamic raw) {
    if (raw is List) return raw;
    if (raw is Map) {
      final data = raw['data'];
      if (data is List) return data;
      final routes = raw['routes'];
      if (routes is List) return routes;
    }
    return const [];
  }

  static int currentPageFrom(dynamic raw, int fallback) {
    if (raw is Map) {
      final page = toInt(raw['currentPage'] ?? raw['current_page']);
      if (page > 0) return page;
    }
    return fallback;
  }

  static bool hasMorePages(
    Map<String, dynamic> pagination, {
    required int fallbackPage,
    required int perPage,
    required int itemCount,
  }) {
    final currentPage = toInt(
      pagination['currentPage'] ??
          pagination['current_page'] ??
          fallbackPage,
    );
    final page = currentPage > 0 ? currentPage : fallbackPage;

    final totalPage = toInt(
      pagination['totalPage'] ??
          pagination['total_page'] ??
          pagination['last_page'] ??
          pagination['lastPage'],
    );
    if (totalPage > 0) return page < totalPage;

    final totalRecords = toInt(
      pagination['totalRecords'] ??
          pagination['total_records'] ??
          pagination['total'] ??
          pagination['total_count'],
    );
    if (totalRecords > 0) return page * perPage < totalRecords;

    return itemCount >= perPage;
  }

  static int toInt(dynamic value) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
