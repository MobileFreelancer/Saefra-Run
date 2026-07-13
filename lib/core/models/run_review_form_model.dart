enum RouteFeel { openWellTraveled, balanced, quietSecluded }

enum RouteSurfaceType { mostlyPaved, mixedSurfaces, mostlyUnpaved }

enum SidewalkAvailability { yes, someSections, no }

class RunReviewFormModel {
  final RouteFeel routeFeel;
  final RouteSurfaceType surfaceType;
  final SidewalkAvailability sidewalks;
  final int starRating;
  final String reviewText;
  final List<String> imagePaths;

  const RunReviewFormModel({
    this.routeFeel = RouteFeel.balanced,
    this.surfaceType = RouteSurfaceType.mixedSurfaces,
    this.sidewalks = SidewalkAvailability.someSections,
    this.starRating = 0,
    this.reviewText = '',
    this.imagePaths = const [],
  });

  RunReviewFormModel copyWith({
    RouteFeel? routeFeel,
    RouteSurfaceType? surfaceType,
    SidewalkAvailability? sidewalks,
    int? starRating,
    String? reviewText,
    List<String>? imagePaths,
  }) {
    return RunReviewFormModel(
      routeFeel: routeFeel ?? this.routeFeel,
      surfaceType: surfaceType ?? this.surfaceType,
      sidewalks: sidewalks ?? this.sidewalks,
      starRating: starRating ?? this.starRating,
      reviewText: reviewText ?? this.reviewText,
      imagePaths: imagePaths ?? this.imagePaths,
    );
  }

  Map<String, dynamic> toJson() => {
        'route_feel': routeFeel.name,
        'surface_type': surfaceType.name,
        'sidewalks': sidewalks.name,
        'star_rating': starRating,
        'review_text': reviewText,
        'image_paths': imagePaths,
      };
}

extension RouteFeelLabel on RouteFeel {
  String get label => switch (this) {
        RouteFeel.openWellTraveled => 'Open and well-traveled',
        RouteFeel.balanced => 'Balanced',
        RouteFeel.quietSecluded => 'Quiet and secluded',
      };
}

extension RouteSurfaceTypeLabel on RouteSurfaceType {
  String get label => switch (this) {
        RouteSurfaceType.mostlyPaved => 'Mostly paved',
        RouteSurfaceType.mixedSurfaces => 'Mixed surfaces',
        RouteSurfaceType.mostlyUnpaved => 'Mostly unpaved',
      };
}

extension SidewalkAvailabilityLabel on SidewalkAvailability {
  String get label => switch (this) {
        SidewalkAvailability.yes => 'Yes',
        SidewalkAvailability.someSections => 'Some sections',
        SidewalkAvailability.no => 'No',
      };
}
