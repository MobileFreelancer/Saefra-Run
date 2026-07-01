import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:saefra_run/core/services/secure_storage_service.dart';
import 'package:saefra_run/core/config/api_config.dart';
import 'package:saefra_run/core/models/onboarding_model.dart';
import 'package:saefra_run/core/models/user_model.dart';
import 'package:saefra_run/core/services/api_service.dart';
import 'package:saefra_run/core/services/secure_storage_service.dart';
import 'package:saefra_run/core/services/socil_auth%20services.dart';

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final ApiService _apiService = ApiService();
  final FlutterSecureStorage _storage = SecureStorageService.instance;

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _error;
  String? _pendingResetEmail;
  String? _pendingResetOtp;

  String? _pendingSignupEmail;
  String? _pendingSignupPassword;

  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get pendingResetIdentifier => _pendingResetEmail;
  bool get hasPendingSignup =>
      _pendingSignupEmail != null && _pendingSignupPassword != null;

  bool _agreedToTerms = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  bool get agreedToTerms => _agreedToTerms;
  bool get obscurePassword => _obscurePassword;
  bool get obscureConfirmPassword => _obscureConfirmPassword;

  void toggleTerms() {
    _agreedToTerms = !_agreedToTerms;
    notifyListeners();
  }

  void setTerms(bool value) {
    _agreedToTerms = value;
    notifyListeners();
  }

  void togglePasswordVisibility() {
    _obscurePassword = !_obscurePassword;
    notifyListeners();
  }

  void toggleConfirmPasswordVisibility() {
    _obscureConfirmPassword = !_obscureConfirmPassword;
    notifyListeners();
  }


  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? value) {
    _error = value;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> initialize() async {
    try {
      final token = await _storage
          .read(key: ApiConfig.storageKeyAccessToken)
          .timeout(const Duration(seconds: 5));

      if (token != null && token.isNotEmpty) {
        _currentUser = await _apiService.getCurrentUser();
        notifyListeners();
      }
    } catch (e, s) {
      debugPrint('AUTH initialize failed: $e');
      debugPrint('$s');
      await _clearTokens();
      _currentUser = null;
    }
  }

  Future<bool> login({
    required String identifier,
    required String password,
  }) async {
    _setLoading(true);
    _setError(null);
    _clearPendingSignup();
    try {
      final response = await _apiService.login(
        email: identifier.trim(),
        password: password,
      );
      await _persistSession(response);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Saves signup credentials locally; registration API runs after onboarding.
  void startSignup({
    required String email,
    required String password,
  }) {
    _pendingSignupEmail = email.trim();
    _pendingSignupPassword = password;
    _setError(null);
    notifyListeners();
  }

  Future<bool> completeSignupWithOnboarding(OnboardingModel onboarding) async {
    final email = _pendingSignupEmail;
    final password = _pendingSignupPassword;
    if (email == null || password == null) {
      _setError('Signup session expired. Please register again.');
      return false;
    }

    _setLoading(true);
    _setError(null);
    try {
      final response = await _apiService.registerFromOnboarding(
        email: email,
        password: password,
        onboarding: onboarding,
      );
      await _persistSession(response);
      _clearPendingSignup();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> forgotPassword({required String identifier}) async {
    _setLoading(true);
    _setError(null);
    _pendingResetOtp = null;
    try {
      await _apiService.forgotPassword(email: identifier.trim());
      _pendingResetEmail = identifier.trim();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Stores OTP locally; backend validates it on reset-password.
  Future<bool> verifyOtp({required String code}) async {
    if (_pendingResetEmail == null) {
      _setError('No pending verification. Please restart reset flow.');
      return false;
    }
    if (code.length != 6) {
      _setError('Please enter the 6-digit OTP.');
      return false;
    }
    _pendingResetOtp = code;
    _setError(null);

    try {
      await _apiService.verifyOtp(
         email: _pendingResetEmail.toString(),
        otp: _pendingResetOtp.toString(),
      );
      _pendingResetOtp = null;
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }


    return true;
  }

  Future<bool> resetPassword({
    required String newPassword,
    required String confirmPassword,
  }) async {
    final email = _pendingResetEmail;
    try {
      await _apiService.resetPassword(
        email: email.toString(),
        password: newPassword,
        passwordConfirmation: confirmPassword,
      );
      _pendingResetEmail = null;
      _pendingResetOtp = null;
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    _setLoading(true);
    try {
      await _apiService.logout();
    } finally {
      await _clearTokens();
      _currentUser = null;
      _pendingResetEmail = null;
      _pendingResetOtp = null;
      _clearPendingSignup();
      _setLoading(false);
    }
  }

  Future<void> _persistSession(dynamic response) async {
    await _storage.write(
      key: ApiConfig.storageKeyAccessToken,
      value: response.accessToken,
    );
    await _storage.write(
      key: ApiConfig.storageKeyUserId,
      value: response.user.id,
    );
    _currentUser = response.user;
    notifyListeners();
  }

  Future<void> _clearTokens() async {
    await _storage.delete(key: ApiConfig.storageKeyAccessToken);
    await _storage.delete(key: ApiConfig.storageKeyUserId);
  }

  void _clearPendingSignup() {
    _pendingSignupEmail = null;
    _pendingSignupPassword = null;
  }

void googleLogin( )async{
  try {
    final userCredential = await GoogleAuthService.signIn();
    if (userCredential != null) {
      log("------User Data In Google Side-------");
      log(userCredential.user?.displayName.toString()??"no data");
      log(userCredential.user?.email.toString()??"no data");
      log(userCredential.user?.uid.toString()??"no data");
    }
  } catch (e,l) {
    log(e.toString());
    log(l.toString());
  }
}


}
