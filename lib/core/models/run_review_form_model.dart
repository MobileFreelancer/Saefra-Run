import 'package:saefra_run/core/utils/api_field_mapper.dart';

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

  Map<String, dynamic> toApiFields({
    required String routeId,
    String? runId,
  }) {
    final fields = <String, dynamic>{
      'route_id': routeId,
      'overall_rating': starRating,
      'route_feel': ApiFieldMapper.routeFeelToApi(routeFeel.name),
      'route_surface': ApiFieldMapper.routeSurfaceToApi(surfaceType.name),
      'route_sidewalk': ApiFieldMapper.routeSidewalkToApi(sidewalks.name),
      'comment': reviewText.trim(),
    };
    if (runId != null && runId.trim().isNotEmpty) {
      fields['run_id'] = runId.trim();
    }
    return fields;
  }
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
