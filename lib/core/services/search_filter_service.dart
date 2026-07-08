import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:saefra_run/core/models/search_filter_model.dart';

class SearchFilterService extends ChangeNotifier {
  SearchFilterModel _filters = const SearchFilterModel();

  SearchFilterModel get filters => _filters;

  void toggleRouteTypeExpanded() {
    _filters = _filters.copyWith(
      routeTypeExpanded: !_filters.routeTypeExpanded,
    );
    notifyListeners();
  }

  void toggleDifficultyExpanded() {
    _filters = _filters.copyWith(
      difficultyExpanded: !_filters.difficultyExpanded,
    );
    notifyListeners();
  }

  void toggleDistanceExpanded() {
    _filters = _filters.copyWith(
      distanceExpanded: !_filters.distanceExpanded,
    );
    notifyListeners();
  }

  void toggleRatingExpanded() {
    _filters = _filters.copyWith(
      ratingExpanded: !_filters.ratingExpanded,
    );
    notifyListeners();
  }

  void setRouteType(String? value) {
    _filters = _filters.copyWith(routeType: value);
    notifyListeners();
  }

  void setDifficulty(String? value) {
    _filters = _filters.copyWith(difficulty: value);
    notifyListeners();
  }

  void setDistanceRange(RangeValues value) {
    _filters = _filters.copyWith(distanceRange: value);
    notifyListeners();
  }

  void setRatingRange(RangeValues value) {
    _filters = _filters.copyWith(ratingRange: value);
    notifyListeners();
  }

  void reset() {
    _filters = const SearchFilterModel();
    notifyListeners();
  }
}
