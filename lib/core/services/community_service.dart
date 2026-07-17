import 'package:flutter/foundation.dart';
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
  String? _error;

  List<CommunityRouteModel> get popularRoutes => _popularRoutes;
  List<CommunityRouteModel> get topRatedRoutes => _topRatedRoutes;
  CommunityRouteModel? get selectedRoute => _selectedRoute;
  List<ReviewModel> get reviews => _reviews;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _popularRoutes = await _api.getPopularRoutes();
      _topRatedRoutes = await _api.getTopRatedRoutes();
    } catch (e) {
      _error = e.toString();
      _applyMockRoutes();
    } finally {
      if (_popularRoutes.isEmpty) _applyMockRoutes();
      _isLoading = false;
      notifyListeners();
    }
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
