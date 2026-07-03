import 'package:flutter/foundation.dart';
import 'package:saefra_run/core/models/activity_model.dart';
import 'package:saefra_run/core/models/community_route_model.dart';
import 'package:saefra_run/core/models/review_model.dart';
import 'package:saefra_run/core/services/api_service.dart';

class CommunityService extends ChangeNotifier {
  CommunityService();

  final ApiService _api = ApiService();

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
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadRouteDetail(String routeId) async {
    _isLoading = true;
    notifyListeners();
    try {
      _selectedRoute = await _api.getCommunityRouteDetail(routeId);
      _reviews = await _api.getRouteReviews(routeId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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
}
