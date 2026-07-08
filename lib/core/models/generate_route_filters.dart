enum RouteDifficulty { easy, medium, hard }

enum RouteShape { loop, oneWay }

enum RouteLighting { wellLit, dimDark }

class GenerateRouteFilters {
  final double distanceKm;
  final RouteDifficulty difficulty;
  final RouteShape shape;
  final RouteLighting lighting;

  const GenerateRouteFilters({
    this.distanceKm = 5,
    this.difficulty = RouteDifficulty.medium,
    this.shape = RouteShape.loop,
    this.lighting = RouteLighting.wellLit,
  });

  GenerateRouteFilters copyWith({
    double? distanceKm,
    RouteDifficulty? difficulty,
    RouteShape? shape,
    RouteLighting? lighting,
  }) {
    return GenerateRouteFilters(
      distanceKm: distanceKm ?? this.distanceKm,
      difficulty: difficulty ?? this.difficulty,
      shape: shape ?? this.shape,
      lighting: lighting ?? this.lighting,
    );
  }

  Map<String, dynamic> toQueryParams() => {
        'distance_km': distanceKm.toStringAsFixed(1),
        'difficulty': difficulty.apiValue,
        'route_type': shape == RouteShape.loop ? 'loop' : 'one_way',
        'lighting': lighting == RouteLighting.wellLit ? 'well_lit' : 'dim_dark',
      };
}

extension RouteDifficultyApi on RouteDifficulty {
  String get apiValue => name;
}

extension RouteLightingApi on RouteLighting {
  String get apiValue => this == RouteLighting.wellLit ? 'Well-lit' : 'Dim/Dark';
}
