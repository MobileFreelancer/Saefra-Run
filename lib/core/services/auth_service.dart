import 'dart:developer';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:saefra_run/core/services/secure_storage_service.dart';
import 'package:saefra_run/core/config/api_config.dart';
import 'package:saefra_run/core/models/onboarding_model.dart';
import 'package:saefra_run/core/models/user_model.dart';
import 'package:saefra_run/core/services/api_service.dart';
import 'package:saefra_run/core/services/fcm_service.dart';
import 'package:saefra_run/core/services/social_auth_services.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final ApiService _apiService = ApiService();
  final FlutterSecureStorage _storage = SecureStorageService.instance;

  UserModel? _currentUser;
  String? _sessionToken;
  bool _isLoading = false;
  String? _error;
  String? _pendingResetEmail;
  String? _pendingResetOtp;

  String? _pendingSignupEmail;
  String? _pendingSignupPassword;

  UserModel? get currentUser => _currentUser;
  String? get sessionToken => _sessionToken;

  /// Logged-in state is driven by a persisted access token only.
  bool get isLoggedIn =>
      _sessionToken != null && _sessionToken!.trim().isNotEmpty;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get pendingResetIdentifier => _pendingResetEmail;
  bool get hasPendingSignup =>
      _pendingSignupEmail != null && _pendingSignupPassword != null;

  bool _agreedToTerms = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _sessionLoaded = false;

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
    if (_sessionLoaded) return;

    try {
      _sessionToken = await _storage
          .read(key: ApiConfig.storageKeyAccessToken)
          .timeout(const Duration(seconds: 5));

      if (_sessionToken == null || _sessionToken!.trim().isEmpty) {
        _sessionToken = null;
        _currentUser = null;
        await _restorePendingSignup();
        notifyListeners();
        return;
      }

      // Notify immediately so router/splash see logged-in state from token.
      notifyListeners();

      await _restoreUserProfile();
      notifyListeners();
      await FcmService.requestPermissionAndSync();
    } catch (e, s) {
      debugPrint('AUTH initialize failed: $e');
      debugPrint('$s');
      _sessionToken = await _storage.read(key: ApiConfig.storageKeyAccessToken);
      if (_sessionToken == null || _sessionToken!.trim().isEmpty) {
        await _clearTokens();
        _currentUser = null;
        _sessionToken = null;
      } else {
        await _restoreUserProfile(fromCacheOnly: true);
      }
      notifyListeners();
    } finally {
      _sessionLoaded = true;
    }
  }

  Future<void> syncCurrentUser(UserModel user) async {
    _currentUser = user;
    if (user.id.trim().isNotEmpty) {
      await _storage.write(
        key: ApiConfig.storageKeyUserId,
        value: user.id.trim(),
      );
    }
    if (user.email != null && user.email!.trim().isNotEmpty) {
      await _storage.write(
        key: ApiConfig.storageKeyUserEmail,
        value: user.email!.trim(),
      );
    }
    notifyListeners();
  }

  Future<void> _restoreUserProfile({bool fromCacheOnly = false}) async {
    if (!fromCacheOnly) {
      try {
        await syncCurrentUser(await _apiService.getCurrentUser());
        return;
      } catch (e) {
        debugPrint('getCurrentUser failed, using cached session: $e');
      }
    }

    final userId = await _storage.read(key: ApiConfig.storageKeyUserId);
    final email = await _storage.read(key: ApiConfig.storageKeyUserEmail);

    if (userId != null && userId.trim().isNotEmpty) {
      _currentUser = UserModel(
        id: userId.trim(),
        email: email,
        firstName: email?.split('@').first,
      );
      return;
    }

    // Token exists but profile cache missing — keep session, fetch profile later.
    if (_sessionToken != null && _sessionToken!.trim().isNotEmpty) {
      _currentUser = UserModel(
        id: '',
        email: email,
        firstName: email?.split('@').first,
      );
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

      if (response.accessToken.trim().isEmpty ||
          response.user.id.trim().isEmpty) {
        _setError('Invalid credentials.');
        return false;
      }

      await _persistSession(response);
      await _storage.write(
        key: ApiConfig.storageKeyUserEmail,
        value: identifier.trim(),
      );
      await _storage.write(
        key: ApiConfig.storageKeyUserPassword,
        value: password,
      );
      await FcmService.syncToken();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Saves signup credentials locally; registration API runs after onboarding.
  Future<void> startSignup({
    required String email,
    required String password,
  }) async {
    _pendingSignupEmail = email.trim();
    _pendingSignupPassword = password;
    _setError(null);
    try {
      await _storage.write(
        key: ApiConfig.storageKeyUserEmail,
        value: _pendingSignupEmail,
      );
      await _storage.write(
        key: ApiConfig.storageKeyUserPassword,
        value: password,
      );
      await _storage.write(
        key: ApiConfig.storageKeyPendingSignup,
        value: 'true',
      );
    } catch (e) {
      debugPrint('startSignup persist failed: $e');
    }
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
      await _storage.write(key: ApiConfig.storageKeyUserEmail, value: email);
      await _storage.write(key: ApiConfig.storageKeyUserPassword, value: password);
      await _storage.delete(key: ApiConfig.storageKeyPendingSignup);
      _pendingSignupEmail = null;
      _pendingSignupPassword = null;
      await FcmService.syncToken();
      return true;
    } catch (e) {
      log("Error--> $e");
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

  Future<bool> logout() async {
    _setLoading(true);
    try {
      final email = await _storage.read(key: ApiConfig.storageKeyUserEmail) ??
          _currentUser?.email ??
          '';
      final password =
          await _storage.read(key: ApiConfig.storageKeyUserPassword) ?? '';

      if (email.isNotEmpty && password.isNotEmpty) {
        try {
          await _apiService.logout(email: email, password: password);
        } catch (e) {
          debugPrint('Logout API failed: $e');
        }
      }
      return true;
    } finally {
      await _clearTokens();
      _currentUser = null;
      _sessionToken = null;
      _sessionLoaded = false;
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
    _sessionToken = response.accessToken;
    _currentUser = response.user;
    notifyListeners();
  }

  Future<void> _clearTokens() async {
    await _storage.delete(key: ApiConfig.storageKeyAccessToken);
    await _storage.delete(key: ApiConfig.storageKeyUserId);
    await _storage.delete(key: ApiConfig.storageKeyUserEmail);
    await _storage.delete(key: ApiConfig.storageKeyUserPassword);
    _sessionToken = null;
  }

  Future<void> _restorePendingSignup() async {
    try {
      final pending =
          await _storage.read(key: ApiConfig.storageKeyPendingSignup);
      if (pending != 'true') {
        _clearPendingSignup();
        return;
      }

      _pendingSignupEmail =
          await _storage.read(key: ApiConfig.storageKeyUserEmail);
      _pendingSignupPassword =
          await _storage.read(key: ApiConfig.storageKeyUserPassword);

      if (_pendingSignupEmail == null || _pendingSignupPassword == null) {
        _clearPendingSignup();
      }
    } catch (e) {
      debugPrint('restorePendingSignup failed: $e');
      _clearPendingSignup();
    }
  }

  void _clearPendingSignup() {
    _pendingSignupEmail = null;
    _pendingSignupPassword = null;
    _storage.delete(key: ApiConfig.storageKeyPendingSignup);
  }



  void googleLogin() async {
    try {
      final UserCredential? userCredential = await GoogleAuthService.signIn();

      if (userCredential != null) {
        final user = userCredential.user;

        log("------ User Data -------");
        log("Name: ${user?.displayName}");
        log("Email: ${user?.email}");
        log("UID: ${user?.uid}");
        final idToken = await user?.getIdToken(true);
        log("Firebase ID Token:");
        log(idToken ?? "No ID Token");

        // Refresh Token
        log("Refresh Token:");
        log(user?.refreshToken ?? "No Refresh Token");
      }
    } catch (e, l) {
      log(e.toString());
      log(l.toString());
    }
  }


  Future<UserCredential?> signInWithApple() async {
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      return await FirebaseAuth.instance.signInWithCredential(
        oauthCredential,
      );
    } catch (e) {
      print(e);
      return null;
    }
  }


}
