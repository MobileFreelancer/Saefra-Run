import 'package:saefra_run/core/models/community_route_model.dart';
import 'package:saefra_run/core/utils/community_route_parser.dart';

class CommunityRoutesResult {
  const CommunityRoutesResult({
    required this.popularRoutes,
    required this.recentRoutes,
    this.currentPage = 1,
    this.hasMore = false,
  });

  final List<CommunityRouteModel> popularRoutes;
  final List<CommunityRouteModel> recentRoutes;
  final int currentPage;
  final bool hasMore;

  factory CommunityRoutesResult.fromPayload(
    Map<String, dynamic> payload, {
    required int page,
    required int perPage,
  }) {
    final popularRaw = payload['popular_routes'] ??
        payload['popular'] ??
        payload['popularRoutes'];
    final recentRaw = payload['recent_routes'] ??
        payload['recent'] ??
        payload['top_rated_routes'] ??
        payload['topRatedRoutes'] ??
        payload['recentRoutes'];

    var popularRoutes = CommunityRouteParser.parseRoutes(popularRaw);
    var recentRoutes = CommunityRouteParser.parseRoutes(recentRaw);

    final allRoutes = CommunityRouteParser.parseRoutes(
      payload['routes'] ?? payload['community_routes'],
    );

    if (popularRoutes.isEmpty && recentRoutes.isEmpty && allRoutes.isNotEmpty) {
      final midpoint = (allRoutes.length / 2).ceil();
      popularRoutes = allRoutes.take(midpoint).toList();
      recentRoutes = allRoutes.skip(midpoint).toList();
    } else if (popularRoutes.isEmpty && allRoutes.isNotEmpty) {
      popularRoutes = allRoutes;
    } else if (recentRoutes.isEmpty && allRoutes.isNotEmpty) {
      recentRoutes = allRoutes;
    }

    final popularPagination =
        popularRaw is Map ? Map<String, dynamic>.from(popularRaw) : payload;
    final hasMore = CommunityRouteParser.hasMorePages(
      popularPagination,
      fallbackPage: page,
      perPage: perPage,
      itemCount: popularRoutes.length,
    );

    return CommunityRoutesResult(
      popularRoutes: popularRoutes,
      recentRoutes: recentRoutes,
      currentPage: page,
      hasMore: hasMore,
    );
  }
}
