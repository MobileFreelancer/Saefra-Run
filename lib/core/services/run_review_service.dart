import 'package:flutter/foundation.dart';
import 'package:saefra_run/core/models/run_review_form_model.dart';
import 'package:saefra_run/core/services/api_exception.dart';
import 'package:saefra_run/core/services/api_service.dart';

class RunReviewService extends ChangeNotifier {
  RunReviewService();

  final ApiService _api = ApiService();

  RunReviewFormModel _form = const RunReviewFormModel();
  bool _isSubmitting = false;
  bool _submitted = false;
  String? _error;

  RunReviewFormModel get form => _form;
  bool get isSubmitting => _isSubmitting;
  bool get submitted => _submitted;
  String? get error => _error;

  void setRouteFeel(RouteFeel value) {
    _form = _form.copyWith(routeFeel: value);
    notifyListeners();
  }

  void setSurfaceType(RouteSurfaceType value) {
    _form = _form.copyWith(surfaceType: value);
    notifyListeners();
  }

  void setSidewalks(SidewalkAvailability value) {
    _form = _form.copyWith(sidewalks: value);
    notifyListeners();
  }

  void setStarRating(int value) {
    _form = _form.copyWith(starRating: value.clamp(0, 5));
    notifyListeners();
  }

  void setReviewText(String value) {
    _form = _form.copyWith(reviewText: value);
    notifyListeners();
  }

  void addImage(String path) {
    if (_form.imagePaths.length >= 3) return;
    _form = _form.copyWith(imagePaths: [..._form.imagePaths, path]);
    notifyListeners();
  }

  void removeImage(String path) {
    _form = _form.copyWith(
      imagePaths: _form.imagePaths.where((p) => p != path).toList(),
    );
    notifyListeners();
  }

  Future<bool> submit({
    String? runId,
    required String routeId,
  }) async {
    _isSubmitting = true;
    _error = null;
    notifyListeners();
    try {
      await _api.submitRunReview(
        runId: runId,
        routeId: routeId,
        form: _form,
      );
      _submitted = true;
      _error = null;
      return true;
    } on ApiException catch (e) {
      // Surfaces API business failures such as:
      // {status: Fail, message: You have already reviewed this route.}
      _error = e.message;
      debugPrint('RunReviewService.submit ApiException: ${e.message}');
      return false;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '').trim();
      if (_error == null || _error!.isEmpty) {
        _error = 'Failed to submit review. Please try again.';
      }
      debugPrint('RunReviewService.submit failed: $e');
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  void clearError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }

  void reset() {
    _form = const RunReviewFormModel();
    _submitted = false;
    _error = null;
    notifyListeners();
  }
}
