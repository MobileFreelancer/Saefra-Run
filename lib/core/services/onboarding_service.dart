import 'package:flutter/foundation.dart';
import 'package:saefra_run/core/services/secure_storage_service.dart';
import 'package:saefra_run/core/config/api_config.dart';
import 'package:saefra_run/core/models/onboarding_model.dart';
import 'package:saefra_run/core/services/api_service.dart';

class OnboardingService extends ChangeNotifier {
  static final OnboardingService _instance = OnboardingService._internal();
  factory OnboardingService() => _instance;
  OnboardingService._internal();

  final ApiService _apiService = ApiService();
  final FlutterSecureStorage _storage = SecureStorageService.instance;

  OnboardingModel _data = const OnboardingModel();
  bool _isComplete = false;
  bool _isLoading = false;
  String? _error;

  OnboardingModel get data => _data;
  bool get isComplete => _isComplete;
  bool get isLoading => _isLoading;
  String? get error => _error;

  static const String trainingForAGoal = 'Training for a goal';

  Future<void> initialize() async {
    try {
      final value = await _storage
          .read(key: ApiConfig.storageKeyOnboardingComplete)
          .timeout(const Duration(seconds: 5));
      _isComplete = value == 'true';
    } catch (e) {
      debugPrint('Onboarding initialize failed: $e');
      _isComplete = false;
    }
    notifyListeners();
  }

  void setGender(String gender) {
    _data = _data.copyWith(gender: gender);
    notifyListeners();
  }

  void setActivityLevel(String level) {
    _data = _data.copyWith(activityLevel: level);
    notifyListeners();
  }

  /// Sets the main goal. If the new goal isn't "Training for a goal",
  /// any previously chosen sub-target (5k / Half / Full marathon) is
  /// cleared so stale state can't linger.
  void setGoal(String goal) {
    _data = _data.copyWith(
      goal: goal,
      clearGoalTrainingTarget: goal != trainingForAGoal,
    );
    notifyListeners();
  }

  /// Sets the sub-target shown only under "Training for a goal".
  void setGoalTrainingTarget(String target) {
    _data = _data.copyWith(goalTrainingTarget: target);
    notifyListeners();
  }

  void setDateOfBirth(DateTime dateOfBirth) {
    final now = DateTime.now();
    var age = now.year - dateOfBirth.year;
    final hasHadBirthdayThisYear = (now.month > dateOfBirth.month) ||
        (now.month == dateOfBirth.month && now.day >= dateOfBirth.day);
    if (!hasHadBirthdayThisYear) age -= 1;

    _data = _data.copyWith(dateOfBirth: dateOfBirth, age: age);
    notifyListeners();
  }

  void setAge(int age) {
    _data = _data.copyWith(age: age);
    notifyListeners();
  }

  void setLocationEnabled(bool enabled) {
    _data = _data.copyWith(locationEnabled: enabled);
    notifyListeners();
  }

  void setPushNotifications(bool enabled) {
    _data = _data.copyWith(pushNotificationsEnabled: enabled);
    notifyListeners();
  }

  void setEmailNotifications(bool enabled) {
    _data = _data.copyWith(emailNotificationsEnabled: enabled);
    notifyListeners();
  }

  Future<bool> completeOnboarding() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.submitOnboarding(_data);
      await _storage.write(
        key: ApiConfig.storageKeyOnboardingComplete,
        value: 'true',
      );
      _isComplete = true;
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
