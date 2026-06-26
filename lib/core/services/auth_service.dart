import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:saefra_run/core/config/api_config.dart';
import 'package:saefra_run/core/models/user_model.dart';
import 'package:saefra_run/core/services/api_service.dart';

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final ApiService _apiService = ApiService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _error;
  String? _pendingResetIdentifier;

  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get pendingResetIdentifier => _pendingResetIdentifier;



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
    debugPrint('AUTH: initialize start');

    _setLoading(true);

    try {
      final token = await _storage.read(
        key: ApiConfig.storageKeyAccessToken,
      );

      debugPrint('AUTH: token = $token');

      if (token != null && token.isNotEmpty) {
        debugPrint('AUTH: calling getCurrentUser');
        _currentUser = await _apiService.getCurrentUser();
        debugPrint('AUTH: getCurrentUser completed');
      }
    } catch (e, s) {
      debugPrint('AUTH ERROR: $e');
      debugPrint('$s');
    } finally {
      debugPrint('AUTH: initialize end');
      _setLoading(false);
    }
  }

  Future<bool> login({
    required String identifier,
    required String password,
  }) async {
    _setLoading(true);
    _setError(null);
    try {
      final response = await _apiService.login(
        identifier: identifier,
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

  Future<bool> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _setError(null);
    try {
      final response = await _apiService.register(
        fullName: fullName,
        email: email,
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

  Future<bool> forgotPassword({required String identifier}) async {
    _setLoading(true);
    _setError(null);
    try {
      await _apiService.forgotPassword(identifier: identifier);
      _pendingResetIdentifier = identifier;
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> verifyOtp({required String code}) async {
    final identifier = _pendingResetIdentifier;
    if (identifier == null) {
      _setError('No pending verification. Please restart reset flow.');
      return false;
    }

    _setLoading(true);
    _setError(null);
    try {
      await _apiService.verifyOtp(identifier: identifier, code: code);
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
    final identifier = _pendingResetIdentifier;
    if (identifier == null) {
      _setError('No pending reset. Please restart reset flow.');
      return false;
    }

    _setLoading(true);
    _setError(null);
    try {
      await _apiService.resetPassword(
        identifier: identifier,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );
      _pendingResetIdentifier = null;
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
      _pendingResetIdentifier = null;
      _setLoading(false);
    }
  }

  Future<void> _persistSession(dynamic response) async {
    await _storage.write(
      key: ApiConfig.storageKeyAccessToken,
      value: response.accessToken,
    );
    await _storage.write(
      key: ApiConfig.storageKeyRefreshToken,
      value: response.refreshToken,
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
    await _storage.delete(key: ApiConfig.storageKeyRefreshToken);
    await _storage.delete(key: ApiConfig.storageKeyUserId);
  }
}
