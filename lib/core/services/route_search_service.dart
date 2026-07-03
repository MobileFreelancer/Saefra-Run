import 'package:flutter/foundation.dart';
import 'package:saefra_run/core/models/route_model.dart';
import 'package:saefra_run/core/services/api_service.dart';

enum RouteSearchStatus { idle, loading, notFound, results }

class RouteSearchService extends ChangeNotifier {
  RouteSearchService();

  final ApiService _api = ApiService();

  String _query = '';
  RouteSearchStatus _status = RouteSearchStatus.idle;
  List<RouteModel> _results = [];
  String? _error;

  String get query => _query;
  RouteSearchStatus get status => _status;
  List<RouteModel> get results => _results;
  String? get error => _error;
  bool get isLoading => _status == RouteSearchStatus.loading;

  void setQuery(String value) {
    _query = value;
    notifyListeners();
  }

  Future<void> search([String? queryOverride]) async {
    final q = (queryOverride ?? _query).trim();
    _query = q;
    _error = null;

    if (q.isEmpty) {
      _status = RouteSearchStatus.idle;
      _results = [];
      notifyListeners();
      return;
    }

    _status = RouteSearchStatus.loading;
    notifyListeners();

    try {
      final list = await _api.searchRoutes(q);
      _results = list;
      _status =
          list.isEmpty ? RouteSearchStatus.notFound : RouteSearchStatus.results;
    } catch (e) {
      _error = e.toString();
      _status = RouteSearchStatus.notFound;
      _results = [];
    }
    notifyListeners();
  }

  void reset() {
    _query = '';
    _status = RouteSearchStatus.idle;
    _results = [];
    _error = null;
    notifyListeners();
  }
}
