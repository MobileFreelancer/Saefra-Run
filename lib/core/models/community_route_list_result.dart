import 'package:saefra_run/core/models/community_route_model.dart';
import 'package:saefra_run/core/utils/community_route_parser.dart';

class CommunityRouteListResult {
  const CommunityRouteListResult({
    required this.routes,
    this.currentPage = 1,
    this.hasMore = false,
  });

  final List<CommunityRouteModel> routes;
  final int currentPage;
  final bool hasMore;

  factory CommunityRouteListResult.fromPayload(
    Map<String, dynamic> payload, {
    required int page,
    required int perPage,
  }) {
    final routesRaw = payload['routes'] ??
        payload['popular_routes'] ??
        payload['popularRoutes'] ??
        payload['recent_routes'] ??
        payload['recentRoutes'] ??
        payload;

    final routes = CommunityRouteParser.parseRoutes(routesRaw);
    final paginationSource = routesRaw is Map
        ? Map<String, dynamic>.from(routesRaw)
        : payload;

    final currentPage = CommunityRouteParser.currentPageFrom(
      paginationSource,
      page,
    );
    final hasMore = CommunityRouteParser.hasMorePages(
      paginationSource,
      fallbackPage: page,
      perPage: perPage,
      itemCount: routes.length,
    );

    return CommunityRouteListResult(
      routes: routes,
      currentPage: currentPage,
      hasMore: hasMore,
    );
  }
}
