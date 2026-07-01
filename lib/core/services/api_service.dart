import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:saefra_run/core/config/api_config.dart';
import 'package:saefra_run/core/models/auth_response_model.dart';
import 'package:saefra_run/core/models/onboarding_model.dart';
import 'package:saefra_run/core/models/user_model.dart';
import 'package:saefra_run/core/services/api_exception.dart';
import 'package:saefra_run/core/services/secure_storage_service.dart';
import 'package:saefra_run/core/utils/api_response_parser.dart';
import 'package:saefra_run/core/utils/formatters.dart';
import 'dart:developer' as developer;
import '../models/user_preferences_model.dart';
import '../utils/api_field_mapper.dart';
import '../utils/app_loader.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal() {
    _setupDio();
  }

  late final Dio _dio;
  final FlutterSecureStorage _storage = SecureStorageService.instance;

  void _setupDio() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: ApiConfig.connectTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
        headers: {
          'Accept': 'application/json',
          ApiConfig.ngrokSkipBrowserWarning: 'true',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token =
          await _storage.read(key: ApiConfig.storageKeyAccessToken);

          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          // Generate cURL
          final curl = StringBuffer()
            ..write('curl -X ${options.method}');

          options.headers.forEach((key, value) {
            curl.write(" -H '$key: $value'");
          });

          if (options.data != null) {
            if (options.data is FormData) {
              final formData = options.data as FormData;

              for (final field in formData.fields) {
                curl.write(" -F '${field.key}=${field.value}'");
              }

              for (final file in formData.files) {
                curl.write(" -F '${file.key}=@${file.value.filename}'");
              }
            } else {
              curl.write(" -d '${options.data}'");
            }
          }

          curl.write(" '${options.uri}'");

          developer.log(
            '\n========== API REQUEST ==========\n'
                '${curl.toString()}\n'
                '================================',
          );

          handler.next(options);
        },

        onResponse: (response, handler) {
          developer.log(
            '\n========== API RESPONSE ==========\n'
                'URL: ${response.requestOptions.uri}\n'
                'Status: ${response.statusCode}\n'
                'Body: ${response.data}\n'
                '=================================',
          );

          handler.next(response);
        },

        onError: (e, handler) {
          developer.log(
            '\n========== API ERROR ==========\n'
                'URL: ${e.requestOptions.uri}\n'
                'Status: ${e.response?.statusCode}\n'
                'Response: ${e.response?.data}\n'
                'Message: ${e.message}\n'
                '===============================',
          );

          handler.next(e);
        },
      ),
    );
  }

  String _path(String segment) {
    if (segment.startsWith('/api/')) return segment;
    if (segment.startsWith('/')) return '/api$segment';
    return '/api/$segment';
  }

  FormData _form(Map<String, dynamic> fields) {
    return FormData.fromMap(fields);
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

    final serverMessage = ApiResponseParser.parseErrorMessage(data);

    switch (statusCode) {
      case 400:
        return ApiException(
          serverMessage == 'Something went wrong.'
              ? 'Invalid request. Please check your input.'
              : serverMessage,
          statusCode,
        );
      case 401:
        return ApiException(
          serverMessage == 'Something went wrong.'
              ? 'Invalid credentials. Please try again.'
              : serverMessage,
          statusCode,
        );
      case 403:
        final msg = serverMessage;
        if (msg.toLowerCase().contains('token')) {
          return ApiException(msg, statusCode);
        }
        return ApiException(
          msg == 'Something went wrong.' ? 'Access denied.' : msg,
          statusCode,
        );
      case 404:
        return const ApiException('Service not found.', 404);
      case 422:
        return ApiException(serverMessage, statusCode);
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
          serverMessage == 'Something went wrong.'
              ? 'Server error. Please try again later.'
              : serverMessage,
          statusCode,
        );
      default:
        return ApiException(
          serverMessage == 'Something went wrong.'
              ? (e.message ?? 'Something went wrong.')
              : serverMessage,
          statusCode,
        );
    }
  }

  void _ensureSuccess(Response<dynamic> response, {String fallback = 'Request failed.'}) {
    if (!ApiResponseParser.isSuccess(response.data, response.statusCode)) {
      throw ApiException(
        ApiResponseParser.parseErrorMessage(response.data, fallback: fallback),
        response.statusCode,
      );
    }
  }

  Map<String, dynamic> _map(Response<dynamic> response) {
    _ensureSuccess(response);
    return ApiResponseParser.asMap(response.data);
  }

  Future<void> _mockDelay() => Future<void>.delayed(const Duration(milliseconds: 800));

  // ─── Auth ───────────────────────────────────────────────────────────────────

  Future<AuthResponseModel> login({
    required String email,
    required String password,
  }) async {
    AppLoader.show();
    if (ApiConfig.useMockApi) {
      await _mockDelay();
      return AuthResponseModel(
        accessToken: 'mock_token',
        user: UserModel(id: '1', email: email),
      );
    }

    try {
      final response = await _dio.post(
        _path('/auth/login'),
        data: _form({'email': email, 'password': password}),
      );
      AppLoader.hide();
      return AuthResponseModel.fromJson(_map(response));
    } on DioException catch (e) {
      AppLoader.hide();
      throw _handleDioError(e);
    }
  }

  Future<AuthResponseModel> register({
    required String email,
    required String password,
    required String passwordConfirmation,
    required String gender,
    required String birthdate,
    required String visitReason,
    required String runPreference,
  }) async {
    AppLoader.show();
    if (ApiConfig.useMockApi) {
      await _mockDelay();
      return AuthResponseModel(
        accessToken: 'mock_token',
        user: UserModel(id: '1', email: email),
      );
    }

    try {
      final response = await _dio.post(
        _path('/auth/register'),
        data: _form({
          'email': email,
          'password': password,
          'password_confirmation': passwordConfirmation,
          'gender': gender,
          'birthdate': birthdate,
          'visit_reason': visitReason,
          'run_preference': runPreference,
        }),
      );
      AppLoader.hide();
      return AuthResponseModel.fromJson(_map(response));
    } on DioException catch (e) {
      AppLoader.hide();
      throw _handleDioError(e);
    }
  }

  Future<AuthResponseModel> registerFromOnboarding({
    required String email,
    required String password,
    required OnboardingModel onboarding,
  }) {
    final fields = ApiFieldMapper.registerFormFromOnboarding(
      email: email,
      password: password,
      onboarding: onboarding,
    );
    return register(
      email: fields['email'] as String,
      password: fields['password'] as String,
      passwordConfirmation: fields['password_confirmation'] as String,
      gender: fields['gender'] as String,
      birthdate: fields['birthdate'] as String,
      visitReason: fields['visit_reason'] as String,
      runPreference: fields['run_preference'] as String,
    );
  }

  Future<String> forgotPassword({required String email}) async {
    AppLoader.show();
    if (ApiConfig.useMockApi) {
      await _mockDelay();
      return 'OTP sent successfully.';
    }

    try {
      final response = await _dio.post(
        _path('/auth/forgot-password'),
        data: _form({'email': email}),
      );
      final map = _map(response);
      AppLoader.hide();
      return map['message'] as String? ?? 'OTP sent successfully.';
    } on DioException catch (e) {
      AppLoader.hide();
      throw _handleDioError(e);
    }
  }



  Future<void> verifyOtp({
    required String email,
    required String otp,
  }) async {
    AppLoader.show();
    if (ApiConfig.useMockApi) {
      await _mockDelay();
      return;
    }

    try {
      final response = await _dio.post(
        _path('/auth/varify-otp'),
        data: _form({
          'email': email,
          'otp': otp,
        }),
      );
      AppLoader.hide();
      _map(response);
    } on DioException catch (e) {
      AppLoader.hide();
      throw _handleDioError(e);
    }
  }



  Future<void> resetPassword({
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    AppLoader.show();
    if (ApiConfig.useMockApi) {
      await _mockDelay();
      if (password != passwordConfirmation) {
        throw const ApiException('Passwords do not match.', 422);
      }
      return;
    }

    try {
      final response = await _dio.post(
        _path('/auth/reset-password'),
        data: _form({
          'email': email,
          'password': password,
          'password_confirmation': passwordConfirmation,
        }),
      );
      AppLoader.hide();
      _map(response);
    } on DioException catch (e) {
      AppLoader.hide();
      throw _handleDioError(e);
    }
  }

  Future<void> logout() async {
    try {
      await _storage.delete(key: ApiConfig.storageKeyAccessToken);
      await _storage.delete(key: ApiConfig.storageKeyUserId);
    } catch (_) {}
  }

  // ─── Profile ────────────────────────────────────────────────────────────────

  Future<UserModel> getCurrentUser() async {
    if (ApiConfig.useMockApi) {
      await _mockDelay();
      final userId = await _storage.read(key: ApiConfig.storageKeyUserId);
      if (userId == null) {
        throw const ApiException('Not authenticated.', 401);
      }
      return UserModel(id: userId);
    }

    try {
      final response = await _dio.get(_path('/profile'));
      final map = _map(response);
      return UserModel.fromJson(ApiResponseParser.asMap(map['user']));
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<UserModel> updateProfile({
    required String gender,
    required String birthdate,
  }) async {
    try {
      final parsed = DateTime.parse(birthdate); // if it's yyyy-MM-dd
      final formatted = DateFormat('M-d-yyyy').format(parsed);
      final response = await _dio.post(
        _path('/profile'),
        data: _form({'gender': gender, 'birthdate': formatted}),
      );
      final map = _map(response);
      return UserModel.fromJson(ApiResponseParser.asMap(map['user']));
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<UserModel> updateProfileFromOnboarding(OnboardingModel onboarding) {
    final fields = ApiFieldMapper.profileFormFromOnboarding(onboarding);
    return updateProfile(
      gender: fields['gender'] as String,
      birthdate: fields['birthdate'] as String,
    );
  }

  // ─── Preferences ────────────────────────────────────────────────────────────

  Future<UserPreferencesModel> getPreferences() async {
    try {
      final response = await _dio.get(_path('/preferences'));
      final map = _map(response);
      return UserPreferencesModel.fromJson(
        ApiResponseParser.asMap(map['preferences']),
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<void> updatePreferences({
    String? visitReason,
    String? runPreference,
  }) async {
    try {
      final response = await _dio.post(
        _path('/preferences'),
        queryParameters: {
          if (visitReason != null) 'visit_reason': visitReason,
          if (runPreference != null) 'run_preference': runPreference,
        },
      );
      _map(response);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }


  Future<void> syncOnboardingForLoggedInUser(OnboardingModel onboarding) async {
    if (ApiConfig.useMockApi) {
      await _mockDelay();
      return;
    }

    await updateProfileFromOnboarding(onboarding);
    await updatePreferences(
      visitReason: ApiFieldMapper.visitReasonToApi(onboarding.goal),
      runPreference: ApiFieldMapper.runPreferenceToApi(onboarding.activityLevel),
    );
  }

  Future<Map<String, dynamic>> generateSafeRoute({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
  }) async {
    AppLoader.show();
    if (ApiConfig.useMockApi) {
      await _mockDelay();
      return {
        "success": true,
        "message": "Safest route generated successfully.",
        "route": {
          "recommended_routes": {
            "route_id": 101,
            "route_name": "Safest Route",
            "route_image": "",
            "distance": 4.96,
            "estimated_duration": 68,
            "starting_point": "Origin",
            "ending_point": "Destination",
            "runner_count": 0,
            "is_secure": true,
            "start_latitude": 21.2158,
            "start_longitude": 72.8372,
            "end_latitude": 21.2035,
            "end_longitude": 72.7997,
            "route_coordinates": "otn`Cq_q{LFdCtACfAIhDKlBCJDHR`@zAh@~A@NFDh@tGHf@FJ@JF@BDT@VLj@|CXtDJxDH^EP`@nCNp@j@tCf@~CAf@U`B?p@J`@RVPPbAh@LNLb@@V]rB@\\DPVb@fCzAjFnEl@t@R`@b@hBDZNr@jCfO\\rBrPxk@hFhQd@bAb@d@f@Xj@LvCTjEl@hATCBWAsDi@o@zEi@hCShAAhGEhAJF@PIHG@QzAc@zAUdBq@~DAt@ADBPDFD@_BbAFLcBxAJRIlC",
            "safety_score": "74.88%",
            "safety_score_value": 74.88,
            "safepoints": 7
          },
          "recent_routes": [
            {
              "route_id": 1,
              "route_name": "madhi",
              "route_image": "",
              "date": "2026-06-30T17:16:42+00:00",
              "distance": 5.6,
              "duration": 23,
              "tag": "Na"
            }
          ]
        }
      };
    }

    try {
      final response = await _dio.post(
        _path('/routes/generate-safe-route'),
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'X-Goog-Api-Key': '',
            'X-Goog-FieldMask': 'routes.duration,routes.distanceMeters,routes.polyline.encodedPolyline,routes.legs,routes.travelAdvisory,routes.routeLabels',
            'Accept': 'application/json',
          },
        ),
        data: {
          "origin": {
            "location": {
              "latLng": {
                "latitude": originLat,
                "longitude": originLng,
              }
            }
          },
          "destination": {
            "location": {
              "latLng": {
                "latitude": destLat,
                "longitude": destLng,
              }
            }
          },
          "travelMode": "WALK",
          "computeAlternativeRoutes": true,
          "languageCode": "en-US",
          "units": "METRIC"
        },
      );
      AppLoader.hide();
      return _map(response);
    } on DioException catch (e) {
      AppLoader.hide();
      throw _handleDioError(e);
    }
  }

}
