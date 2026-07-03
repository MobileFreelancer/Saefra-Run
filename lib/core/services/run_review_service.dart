import 'package:flutter/foundation.dart';
import 'package:saefra_run/core/models/run_review_form_model.dart';
import 'package:saefra_run/core/services/api_service.dart';

class RunReviewService extends ChangeNotifier {
  RunReviewService();

  final ApiService _api = ApiService();

  RunReviewFormModel _form = const RunReviewFormModel();
  bool _isSubmitting = false;
  bool _submitted = false;

  RunReviewFormModel get form => _form;
  bool get isSubmitting => _isSubmitting;
  bool get submitted => _submitted;

  void setCompanion(RunCompanion value) {
    _form = _form.copyWith(companion: value);
    notifyListeners();
  }

  void toggleEnvironmentTag(String tag) {
    final tags = List<String>.from(_form.environmentTags);
    if (tags.contains(tag)) {
      tags.remove(tag);
    } else {
      tags.add(tag);
    }
    _form = _form.copyWith(environmentTags: tags);
    notifyListeners();
  }

  void setAccuracy(String value) {
    _form = _form.copyWith(accuracyRating: value);
    notifyListeners();
  }

  void setRunMode(String value) {
    _form = _form.copyWith(runMode: value);
    notifyListeners();
  }

  void setFeedback(String value) {
    _form = _form.copyWith(feedback: value);
    notifyListeners();
  }

  void setSurface(RunSurface value) {
    _form = _form.copyWith(surface: value);
    notifyListeners();
  }

  void setWeather(RunWeather value) {
    _form = _form.copyWith(weather: value);
    notifyListeners();
  }

  void addImage(String path) {
    _form = _form.copyWith(imagePaths: [..._form.imagePaths, path]);
    notifyListeners();
  }

  void removeImage(String path) {
    _form = _form.copyWith(
      imagePaths: _form.imagePaths.where((p) => p != path).toList(),
    );
    notifyListeners();
  }

  Future<bool> submit({String? runId}) async {
    _isSubmitting = true;
    notifyListeners();
    try {
      await _api.submitRunReview(
        runId: runId ?? 'latest',
        form: _form,
      );
      _submitted = true;
      return true;
    } catch (_) {
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  void reset() {
    _form = const RunReviewFormModel();
    _submitted = false;
    notifyListeners();
  }
}
