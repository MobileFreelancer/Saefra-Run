import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:saefra_run/core/config/api_config.dart';
import 'package:saefra_run/core/models/onboarding_model.dart';
import 'package:saefra_run/core/models/user_model.dart';
import 'package:saefra_run/core/services/api_service.dart';
import 'package:saefra_run/core/services/auth_service.dart';
import 'package:saefra_run/core/services/secure_storage_service.dart';

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
  String? _lastRoute;

  static const String trainingForAGoal = 'Training for a goal';

  static const onboardingRoutes = [
    '/onboarding/gender',
    '/onboarding/basic-info',
    '/onboarding/activity-level',
    '/onboarding/goal',
    '/onboarding/location',
    '/onboarding/notifications',
  ];

  OnboardingModel get data => _data;
  bool get isComplete => _isComplete;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get resumeRoute => _resolveResumeRoute();

  Future<void> initialize() async {
    try {
      final value = await _storage
          .read(key: ApiConfig.storageKeyOnboardingComplete)
          .timeout(const Duration(seconds: 5));
      _isComplete = value == 'true';

      _lastRoute =
          await _storage.read(key: ApiConfig.storageKeyOnboardingRoute);

      final draft =
          await _storage.read(key: ApiConfig.storageKeyOnboardingDraft);
      if (draft != null && draft.isNotEmpty) {
        final decoded = jsonDecode(draft);
        if (decoded is Map) {
          _data = OnboardingModel.fromJson(
            Map<String, dynamic>.from(decoded),
          );
        }
      }
    } catch (e) {
      debugPrint('Onboarding initialize failed: $e');
      _isComplete = false;
    }
    notifyListeners();
  }

  Future<void> resetForNewSignup() async {
    _data = const OnboardingModel();
    _isComplete = false;
    _error = null;
    _lastRoute = null;
    try {
      await _storage.delete(key: ApiConfig.storageKeyOnboardingComplete);
      await _clearProgress();
    } catch (e) {
      debugPrint('Onboarding resetForNewSignup failed: $e');
    }
    notifyListeners();
  }

  Future<void> saveProgress(String route) async {
    if (!onboardingRoutes.contains(route)) return;
    _lastRoute = route;
    try {
      await _storage.write(
        key: ApiConfig.storageKeyOnboardingRoute,
        value: route,
      );
      await _storage.write(
        key: ApiConfig.storageKeyOnboardingDraft,
        value: jsonEncode(_data.toJson()),
      );
    } catch (e) {
      debugPrint('Onboarding saveProgress failed: $e');
    }
    notifyListeners();
  }

  Future<void> _clearProgress() async {
    _lastRoute = null;
    try {
      await _storage.delete(key: ApiConfig.storageKeyOnboardingRoute);
      await _storage.delete(key: ApiConfig.storageKeyOnboardingDraft);
    } catch (e) {
      debugPrint('Onboarding _clearProgress failed: $e');
    }
  }

  String _resolveResumeRoute() {
    if (_isComplete) return '/dashboard';

    if (_lastRoute != null && onboardingRoutes.contains(_lastRoute)) {
      return _lastRoute!;
    }

    return _routeFromIncompleteData(_data);
  }

  String _routeFromIncompleteData(OnboardingModel model) {
    if (model.gender == null || model.gender!.isEmpty) {
      return '/onboarding/gender';
    }
    if (model.activityLevel == null || model.activityLevel!.isEmpty) {
      return '/onboarding/activity-level';
    }
    if (model.goal == null || model.goal!.isEmpty) {
      return '/onboarding/goal';
    }
    if (!model.locationEnabled) {
      return '/onboarding/location';
    }
    return '/onboarding/notifications';
  }

  void applyUserProfile(UserModel? user) {
    if (user == null) return;
    _data = _data.copyWith(
      firstName: user.firstName ?? _data.firstName,
      lastName: user.lastName ?? _data.lastName,
      gender: user.gender ?? _data.gender,
      dateOfBirth: user.birthdate ?? _data.dateOfBirth,
      age: user.age ?? _data.age,
    );
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

  void setGoal(String goal) {
    _data = _data.copyWith(
      goal: goal,
      clearGoalTrainingTarget: goal != trainingForAGoal,
    );
    notifyListeners();
  }

  void setGoalTrainingTarget(String target) {
    _data = _data.copyWith(goalTrainingTarget: target);
    notifyListeners();
  }

  void setFirstName(String value) {
    _data = _data.copyWith(firstName: value.trim());
    notifyListeners();
  }

  void setLastName(String value) {
    _data = _data.copyWith(lastName: value.trim());
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

  Future<void> markCompleteLocally() async {
    if (_isComplete) return;
    try {
      await _storage.write(
        key: ApiConfig.storageKeyOnboardingComplete,
        value: 'true',
      );
      _isComplete = true;
      await _clearProgress();
      notifyListeners();
    } catch (e) {
      debugPrint('Onboarding markCompleteLocally failed: $e');
    }
  }

  Future<bool> completeOnboarding(AuthService auth) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (auth.hasPendingSignup) {
        final ok = await auth.completeSignupWithOnboarding(_data);
        if (!ok) {
          _error = auth.error ?? 'Registration failed.';
          return false;
        }
      } else if (auth.isLoggedIn) {
        await _apiService.syncOnboardingForLoggedInUser(_data);
      } else {
        _error = 'Please log in or sign up to continue.';
        return false;
      }

      await _storage.write(
        key: ApiConfig.storageKeyOnboardingComplete,
        value: 'true',
      );
      _isComplete = true;
      await _clearProgress();
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
