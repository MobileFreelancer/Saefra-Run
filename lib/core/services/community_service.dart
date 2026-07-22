import 'dart:async';

import 'package:flutter/material.dart';
import 'package:saefra_run/core/mock/feature_mock_data.dart';
import 'package:saefra_run/core/models/community_route_model.dart';
import 'package:saefra_run/core/models/review_model.dart';
import 'package:saefra_run/core/models/route_review_list_result.dart';
import 'package:saefra_run/core/services/api_service.dart';

class CommunityService extends ChangeNotifier {
  CommunityService();

  final ApiService _api = ApiService();

  final searchController = TextEditingController();

  List<CommunityRouteModel> _popularRoutes = [];
  List<CommunityRouteModel> _topRatedRoutes = [];
  CommunityRouteModel? _selectedRoute;
  RouteReviewStatistics? _reviewStatistics;
  List<ReviewModel> _reviews = [];
  List<String> _reviewPhotos = [];
  bool _isLoading = false;
  bool _isLoadingMoreReviews = false;
  bool _hasLoaded = false;
  bool _hasMore = false;
  bool _hasMoreReviews = false;
  int _currentPage = 1;
  int _reviewsPage = 1;
  String? _activeReviewsRouteId;
  String? _error;
  Timer? _searchDebounce;

  static const int _perPage = 20;

  List<CommunityRouteModel> get popularRoutes => _popularRoutes;
  List<CommunityRouteModel> get topRatedRoutes => _topRatedRoutes;
  CommunityRouteModel? get selectedRoute => _selectedRoute;
  RouteReviewStatistics? get reviewStatistics => _reviewStatistics;
  Map<int, double> get ratingDistribution =>
      _reviewStatistics?.ratingDistribution ?? const {};
  List<ReviewModel> get reviews => _reviews;
  List<String> get reviewPhotos => _reviewPhotos;
  bool get isLoading => _isLoading;
  bool get isLoadingMoreReviews => _isLoadingMoreReviews;
  bool get hasMore => _hasMore;
  bool get hasMoreReviews => _hasMoreReviews;
  String? get error => _error;

  double get selectedRouteRating =>
      _reviewStatistics?.averageRating ?? _selectedRoute?.rating ?? 0;

  int get selectedRouteReviewCount =>
      _reviewStatistics?.totalReviews ?? _selectedRoute?.reviewCount ?? 0;

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

  Future<void> loadRouteDetail(String routeId, {bool refresh = false}) async {
    if (!refresh &&
        _activeReviewsRouteId == routeId &&
        _selectedRoute != null &&
        !_isLoading) {
      return;
    }

    _isLoading = true;
    _error = null;
    _reviewsPage = 1;
    _activeReviewsRouteId = routeId;
    notifyListeners();

    try {
      await _loadReviews(routeId, page: 1, append: false);
    } catch (e) {
      _error = e.toString();
      _selectedRoute = null;
      _reviewStatistics = null;
      _reviews = [];
      _reviewPhotos = [];
      _hasMoreReviews = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreReviews() async {
    final routeId = _activeReviewsRouteId;
    if (routeId == null ||
        _isLoading ||
        _isLoadingMoreReviews ||
        !_hasMoreReviews) {
      return;
    }

    _isLoadingMoreReviews = true;
    notifyListeners();

    try {
      await _loadReviews(routeId, page: _reviewsPage + 1, append: true);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoadingMoreReviews = false;
      notifyListeners();
    }
  }

  Future<void> _loadReviews(
    String routeId, {
    required int page,
    required bool append,
  }) async {
    final result = await _api.getRouteReviewList(
      routeId: routeId,
      page: page,
      perPage: _perPage,
    );

    if (!append) {
      _selectedRoute = result.route ??
          CommunityRouteModel(
            id: routeId,
            name: 'Route',
            location: '',
          );
      _reviewStatistics = result.statistics;
      _reviewPhotos = result.photos;
    }

    _reviews = append ? [..._reviews, ...result.reviews] : result.reviews;
    _reviewsPage = result.currentPage;
    _hasMoreReviews = result.hasMore;
  }

  void _applyMockRoutes() {
    _popularRoutes = FeatureMockData.popularRoutes;
    _topRatedRoutes = FeatureMockData.recentRoutes;
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
    String? runId,
  }) async {
    try {
      await _api.submitRouteReview(
        routeId: routeId,
        rating: rating,
        comment: comment,
        runId: runId,
      );
      await _loadReviews(routeId, page: 1, append: false);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
