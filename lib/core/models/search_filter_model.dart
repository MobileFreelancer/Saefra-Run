import 'package:flutter/material.dart';

class SearchFilterModel {
  const SearchFilterModel({
    this.routeType,
    this.difficulty,
    this.distanceRange = const RangeValues(0, 5),
    this.ratingRange = const RangeValues(1, 4),
    this.routeTypeExpanded = false,
    this.difficultyExpanded = false,
    this.distanceExpanded = true,
    this.ratingExpanded = true,
  });

  final String? routeType;
  final String? difficulty;
  final RangeValues distanceRange;
  final RangeValues ratingRange;
  final bool routeTypeExpanded;
  final bool difficultyExpanded;
  final bool distanceExpanded;
  final bool ratingExpanded;

  SearchFilterModel copyWith({
    String? routeType,
    String? difficulty,
    RangeValues? distanceRange,
    RangeValues? ratingRange,
    bool? routeTypeExpanded,
    bool? difficultyExpanded,
    bool? distanceExpanded,
    bool? ratingExpanded,
    bool clearRouteType = false,
    bool clearDifficulty = false,
  }) {
    return SearchFilterModel(
      routeType: clearRouteType ? null : (routeType ?? this.routeType),
      difficulty: clearDifficulty ? null : (difficulty ?? this.difficulty),
      distanceRange: distanceRange ?? this.distanceRange,
      ratingRange: ratingRange ?? this.ratingRange,
      routeTypeExpanded: routeTypeExpanded ?? this.routeTypeExpanded,
      difficultyExpanded: difficultyExpanded ?? this.difficultyExpanded,
      distanceExpanded: distanceExpanded ?? this.distanceExpanded,
      ratingExpanded: ratingExpanded ?? this.ratingExpanded,
    );
  }

  String get distanceLabel =>
      '${distanceRange.start.round()}KM - ${distanceRange.end.round()}KM';

  String get ratingLabel =>
      '${ratingRange.start.round()} STAR - ${ratingRange.end.round()} STAR';
}
