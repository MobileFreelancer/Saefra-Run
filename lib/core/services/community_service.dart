import 'dart:async';

import 'package:flutter/material.dart';
import 'package:saefra_run/core/mock/feature_mock_data.dart';
import 'package:saefra_run/core/models/community_route_model.dart';
import 'package:saefra_run/core/models/review_model.dart';
import 'package:saefra_run/core/services/api_service.dart';

class CommunityService extends ChangeNotifier {
  CommunityService();

  final ApiService _api = ApiService();

  final searchController = TextEditingController();

  List<CommunityRouteModel> _popularRoutes = [];
  List<CommunityRouteModel> _topRatedRoutes = [];
  CommunityRouteModel? _selectedRoute;
  List<ReviewModel> _reviews = [];
  bool _isLoading = false;
  bool _hasLoaded = false;
  bool _hasMore = false;
  int _currentPage = 1;
  String? _error;
  Timer? _searchDebounce;

  static const int _perPage = 20;

  List<CommunityRouteModel> get popularRoutes => _popularRoutes;
  List<CommunityRouteModel> get topRatedRoutes => _topRatedRoutes;
  CommunityRouteModel? get selectedRoute => _selectedRoute;
  List<ReviewModel> get reviews => _reviews;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;
  String? get error => _error;

  Future<void> load({bool refresh = false, String? search}) async {
    if (!refresh && _hasLoaded && _popularRoutes.isNotEmpty) return;

    _isLoading = true;
    _error = null;
    _currentPage = 1;
    notifyListeners();

    try {
      final result = await _api.getCommunityRoutes(
        page: _currentPage,
        perPage: _perPage,
        search: search ?? searchController.text.trim(),
      );
      _popularRoutes = result.popularRoutes;
      _topRatedRoutes = result.recentRoutes;
      _hasMore = result.hasMore;
    } catch (e) {
      _error = e.toString();
      _applyMockRoutes();
    } finally {
      if (_popularRoutes.isEmpty && _topRatedRoutes.isEmpty) {
        _applyMockRoutes();
      }
      _hasLoaded = true;
      _isLoading = false;
      notifyListeners();
    }
  }

  void search(String query) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 450), () {
      load(refresh: true, search: query.trim());
    });
  }

  Future<void> loadRouteDetail(String routeId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _selectedRoute = await _api.getCommunityRouteDetail(routeId);
      _reviews = await _api.getRouteReviews(routeId);
    } catch (e) {
      _error = e.toString();
      _applyMockReviews();
    } finally {
      if (_selectedRoute == null) _applyMockReviews();
      _isLoading = false;
      notifyListeners();
    }
  }

  void _applyMockRoutes() {
    _popularRoutes = FeatureMockData.popularRoutes;
    _topRatedRoutes = FeatureMockData.recentRoutes;
  }

  void _applyMockReviews() {
    _selectedRoute = FeatureMockData.reviewRoute;
    _reviews = FeatureMockData.reviews;
  }

  void toggleLike(String routeId) {
    _popularRoutes = _popularRoutes.map((r) {
      if (r.id == routeId) {
        return CommunityRouteModel(
          id: r.id,
          name: r.name,
          location: r.location,
          distanceKm: r.distanceKm,
          durationMinutes: r.durationMinutes,
          rating: r.rating,
          reviewCount: r.reviewCount,
          likeCount: r.likeCount + 1,
          commentCount: r.commentCount,
          imageAsset: r.imageAsset,
          difficultyTag: r.difficultyTag,
          tags: r.tags,
        );
      }
      return r;
    }).toList();
    notifyListeners();
  }

  Future<bool> submitReview({
    required String routeId,
    required double rating,
    required String comment,
  }) async {
    try {
      await _api.submitRouteReview(
        routeId: routeId,
        rating: rating,
        comment: comment,
      );
      _reviews = await _api.getRouteReviews(routeId);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
