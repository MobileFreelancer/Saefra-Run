import 'package:flutter/foundation.dart';
import 'package:saefra_run/core/models/route_model.dart';
import 'package:saefra_run/core/services/api_service.dart';

class RouteDetailService extends ChangeNotifier {
  RouteDetailService();

  final ApiService _api = ApiService();

  RouteModel? _route;
  bool _isLoading = false;
  String? _error;

  RouteModel? get route => _route;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void setRoute(RouteModel route) {
    _route = route;
    _error = null;
    notifyListeners();
  }

  Future<void> load(String routeId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _route = await _api.getRouteDetail(routeId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clear() {
    _route = null;
    _error = null;
    notifyListeners();
  }
}
