import 'package:dio/dio.dart';
import 'package:saefra_run/core/services/secure_storage_service.dart';
import 'package:saefra_run/core/config/api_config.dart';
import 'package:saefra_run/core/models/auth_response_model.dart';
import 'package:saefra_run/core/models/onboarding_model.dart';
import 'package:saefra_run/core/models/user_model.dart';
import 'package:saefra_run/core/services/api_exception.dart';
import 'package:saefra_run/core/utils/formatters.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal() {
    _setupDio();
  }

  late final Dio _dio;
  final FlutterSecureStorage _storage = SecureStorageService.instance;
  bool _isRefreshing = false;

  void _setupDio() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: ApiConfig.connectTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: ApiConfig.storageKeyAccessToken);
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401 &&
              !error.requestOptions.path.contains('/auth/refresh')) {
            try {
              await _refreshToken();
              final opts = error.requestOptions;
              final token =
                  await _storage.read(key: ApiConfig.storageKeyAccessToken);
              opts.headers['Authorization'] = 'Bearer $token';
              final response = await _dio.fetch(opts);
              return handler.resolve(response);
            } catch (_) {
              return handler.next(error);
            }
          }
          handler.next(error);
        },
      ),
    );
  }

  String _ensureApiPath(String path) {
    if (path.startsWith('/api/')) return path;
    if (path.startsWith('/')) return '/api$path';
    return '/api/$path';
  }

  ApiException _handleDioError(DioException e) {
    final statusCode = e.response?.statusCode;
    final data = e.response?.data;

    if (e.type == DioExceptionType.connectionTimeout) {
      return const ApiException('Connection timed out. Please try again.');
    }
    if (e.type == DioExceptionType.receiveTimeout) {
      return const ApiException('Server took too long to respond.');
    }
    if (e.type == DioExceptionType.connectionError) {
      return const ApiException('No internet connection. Check your network.');
    }

    String? serverMessage;
    if (data is Map<String, dynamic>) {
      serverMessage = data['message'] as String? ?? data['error'] as String?;
    }

    switch (statusCode) {
      case 400:
        return ApiException(
          serverMessage ?? 'Invalid request. Please check your input.',
          statusCode,
        );
      case 401:
        return ApiException(
          serverMessage ?? 'Invalid credentials. Please try again.',
          statusCode,
        );
      case 403:
        final msg = serverMessage ?? '';
        if (msg.toLowerCase().contains('token')) {
          return ApiException(msg, statusCode);
        }
        return ApiException(
          serverMessage ?? 'Access denied.',
          statusCode,
        );
      case 404:
        return const ApiException('Service not found.', 404);
      case 429:
        int? retryAfter;
        if (data is Map<String, dynamic>) {
          retryAfter = data['retryAfter'] as int? ??
              data['retry_after'] as int?;
        }
        retryAfter ??= int.tryParse(
          e.response?.headers.value('retry-after') ?? '',
        );
        final countdown = Formatters.formatRetryCountdown(retryAfter ?? 60);
        return ApiException(
          'Too many requests. Try again in $countdown.',
          statusCode,
          retryAfter,
        );
      case 500:
        return ApiException(
          serverMessage ?? 'Server error. Please try again later.',
          statusCode,
        );
      default:
        return ApiException(
          serverMessage ?? e.message ?? 'Something went wrong.',
          statusCode,
        );
    }
  }

  Future<void> _refreshToken() async {
    if (_isRefreshing) return;
    _isRefreshing = true;
    try {
      final refreshToken =
          await _storage.read(key: ApiConfig.storageKeyRefreshToken);
      if (refreshToken == null) {
        throw const ApiException('Session expired. Please log in again.', 401);
      }
      final response = await _dio.post(
        _ensureApiPath('/auth/refresh'),
        data: {'refresh_token': refreshToken},
      );
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        await _storage.write(
          key: ApiConfig.storageKeyAccessToken,
          value: data['access_token'] as String,
        );
      } else {
        throw ApiException('Token refresh failed.', response.statusCode);
      }
    } finally {
      _isRefreshing = false;
    }
  }

  Future<void> _mockDelay() =>
      Future<void>.delayed(const Duration(milliseconds: 800));

  // ─── Auth ───────────────────────────────────────────────────────────────────

  Future<AuthResponseModel> login({
    required String identifier,
    required String password,
  }) async {
    if (ApiConfig.useMockApi) {
      await _mockDelay();
      return AuthResponseModel(
        accessToken: 'mock_access_token',
        refreshToken: 'mock_refresh_token',
        user: UserModel(
          id: 'mock_user_1',
          email: identifier.contains('@') ? identifier : null,
          phoneNumber: identifier.contains('@') ? null : identifier,
          fullName: 'Saefra Runner',
        ),
      );
    }

    try {
      final response = await _dio.post(
        _ensureApiPath('/auth/login'),
        data: {'identifier': identifier, 'password': password},
      );
      if (response.statusCode == 200) {
        return AuthResponseModel.fromJson(
          response.data as Map<String, dynamic>,
        );
      }
      throw ApiException('Login failed.', response.statusCode);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<AuthResponseModel> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    if (ApiConfig.useMockApi) {
      await _mockDelay();
      return AuthResponseModel(
        accessToken: 'mock_access_token',
        refreshToken: 'mock_refresh_token',
        user: UserModel(
          id: 'mock_user_${DateTime.now().millisecondsSinceEpoch}',
          email: email,
          fullName: fullName,
        ),
      );
    }

    try {
      final response = await _dio.post(
        _ensureApiPath('/auth/register'),
        data: {
          'full_name': fullName,
          'email': email,
          'password': password,
        },
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return AuthResponseModel.fromJson(
          response.data as Map<String, dynamic>,
        );
      }
      throw ApiException('Registration failed.', response.statusCode);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<void> forgotPassword({required String identifier}) async {
    if (ApiConfig.useMockApi) {
      await _mockDelay();
      return;
    }

    try {
      final response = await _dio.post(
        _ensureApiPath('/auth/forgot-password'),
        data: {'identifier': identifier},
      );
      if (response.statusCode != 200) {
        throw ApiException('Request failed.', response.statusCode);
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<void> verifyOtp({
    required String identifier,
    required String code,
  }) async {
    if (ApiConfig.useMockApi) {
      await _mockDelay();
      if (code != '123456') {
        throw const ApiException('Invalid verification code.', 400);
      }
      return;
    }

    try {
      final response = await _dio.post(
        _ensureApiPath('/auth/verify-otp'),
        data: {'identifier': identifier, 'code': code},
      );
      if (response.statusCode != 200) {
        throw ApiException('Verification failed.', response.statusCode);
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<void> resetPassword({
    required String identifier,
    required String newPassword,
    required String confirmPassword,
  }) async {
    if (ApiConfig.useMockApi) {
      await _mockDelay();
      if (newPassword != confirmPassword) {
        throw const ApiException('Passwords do not match.', 400);
      }
      return;
    }

    try {
      final response = await _dio.post(
        _ensureApiPath('/auth/reset-password'),
        data: {
          'identifier': identifier,
          'new_password': newPassword,
          'confirm_password': confirmPassword,
        },
      );
      if (response.statusCode != 200) {
        throw ApiException('Reset failed.', response.statusCode);
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<void> logout() async {
    if (!ApiConfig.useMockApi) {
      try {
        await _dio.post(_ensureApiPath('/auth/logout'));
      } catch (_) {}
    }
  }

  Future<UserModel> getCurrentUser() async {
    if (ApiConfig.useMockApi) {
      await _mockDelay();
      final userId = await _storage.read(key: ApiConfig.storageKeyUserId);
      if (userId == null) {
        throw const ApiException('Not authenticated.', 401);
      }
      return UserModel(id: userId, fullName: 'Saefra Runner');
    }

    try {
      final response = await _dio.get(_ensureApiPath('/users/me'));
      if (response.statusCode == 200) {
        return UserModel.fromJson(response.data as Map<String, dynamic>);
      }
      throw ApiException('Failed to load user.', response.statusCode);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<void> submitOnboarding(OnboardingModel onboarding) async {
    if (ApiConfig.useMockApi) {
      await _mockDelay();
      return;
    }

    try {
      final response = await _dio.post(
        _ensureApiPath('/users/onboarding'),
        data: onboarding.toJson(),
      );
      if (response.statusCode != 200) {
        throw ApiException('Onboarding save failed.', response.statusCode);
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
}
