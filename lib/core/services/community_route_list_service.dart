import 'dart:async';

import 'package:flutter/material.dart';
import 'package:saefra_run/core/mock/feature_mock_data.dart';
import 'package:saefra_run/core/models/community_route_list_result.dart';
import 'package:saefra_run/core/models/community_route_model.dart';
import 'package:saefra_run/core/services/api_service.dart';

enum CommunityRouteListKind { popular, recent }

class CommunityRouteListService extends ChangeNotifier {
  CommunityRouteListService();

  final ApiService _api = ApiService();
  final searchController = TextEditingController();

  CommunityRouteListKind? _kind;
  List<CommunityRouteModel> _routes = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = false;
  int _currentPage = 1;
  String? _error;
  Timer? _searchDebounce;

  static const int _perPage = 20;

  CommunityRouteListKind? get kind => _kind;
  List<CommunityRouteModel> get routes => _routes;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  String? get error => _error;

  String get title => switch (_kind) {
        CommunityRouteListKind.popular => 'Popular Routes',
        CommunityRouteListKind.recent => 'Recent Routes',
        null => 'Routes',
      };

  void init(CommunityRouteListKind kind) {
    _kind = kind;
    _routes = [];
    _currentPage = 1;
    _hasMore = false;
    _error = null;
    searchController.clear();
  }

  Future<void> load({bool refresh = false, String? search}) async {
    if (_kind == null) return;
    if (!refresh && _routes.isNotEmpty) return;

    _isLoading = true;
    _error = null;
    _currentPage = 1;
    notifyListeners();

    try {
      final query = search ?? searchController.text.trim();
      final result = await _fetch(page: 1, search: query);
      _routes = result.routes;
      _hasMore = result.hasMore;
      _currentPage = result.currentPage;
    } catch (e) {
      _error = e.toString();
      _applyMockRoutes();
    } finally {
      if (_routes.isEmpty) _applyMockRoutes();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (_kind == null || _isLoading || _isLoadingMore || !_hasMore) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final nextPage = _currentPage + 1;
      final query = searchController.text.trim();
      final result = await _fetch(page: nextPage, search: query);
      _routes = [..._routes, ...result.routes];
      _hasMore = result.hasMore;
      _currentPage = result.currentPage;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  void search(String query) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 450), () {
      _reloadWithSearch(query.trim());
    });
  }

  Future<void> _reloadWithSearch(String query) async {
    if (_kind == null) return;

    _isLoading = true;
    _error = null;
    _currentPage = 1;
    notifyListeners();

    try {
      final result = await _fetch(
        page: 1,
        search: query.isEmpty ? null : query,
      );
      _routes = result.routes;
      _hasMore = result.hasMore;
      _currentPage = result.currentPage;
    } catch (e) {
      _error = e.toString();
      _routes = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<CommunityRouteListResult> _fetch({
    required int page,
    String? search,
  }) {
    return switch (_kind!) {
      CommunityRouteListKind.popular => _api.getPopularRoutesList(
          page: page,
          perPage: _perPage,
          search: search,
        ),
      CommunityRouteListKind.recent => _api.getRecentRoutesList(
          page: page,
          perPage: _perPage,
          search: search,
        ),
    };
  }

  void _applyMockRoutes() {
    _routes = switch (_kind) {
      CommunityRouteListKind.popular => FeatureMockData.popularRoutes,
      CommunityRouteListKind.recent => FeatureMockData.recentRoutes,
      null => const [],
    };
    _hasMore = false;
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    searchController.dispose();
    super.dispose();
  }
}
