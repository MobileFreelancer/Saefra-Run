import 'package:dio/dio.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:saefra_run/core/config/api_config.dart';
import 'package:saefra_run/core/data/app_mock_data.dart';
import 'package:saefra_run/core/models/activity_model.dart';
import 'package:saefra_run/core/models/auth_response_model.dart';
import 'package:saefra_run/core/models/community_route_model.dart';
import 'package:saefra_run/core/models/emergency_contact_model.dart';
import 'package:saefra_run/core/models/onboarding_model.dart';
import 'package:saefra_run/core/models/review_model.dart';
import 'package:saefra_run/core/models/route_model.dart';
import 'package:saefra_run/core/models/run_review_form_model.dart';
import 'package:saefra_run/core/models/run_session_model.dart';
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
    if (segment.startsWith('/api/v1/')) return segment;
    if (segment.startsWith('/')) return '/api/v1/$segment';
    return '/api/v1/$segment';
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

  /// Uses mock data when [ApiConfig.useMockApi] is true, or when the backend
  /// endpoint is missing (404) or broken (500) so the UI can run on static data.
  Future<T> _apiOrMock<T>(
    Future<T> Function() apiCall,
    Future<T> Function() mockCall,
  ) async {
    if (ApiConfig.useMockApi) {
      await _mockDelay();
      return mockCall();
    }
    try {
      return await apiCall();
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      if (code == 404 || code == 500) {
        return mockCall();
      }
      throw _handleDioError(e);
    }
  }

  Map<String, dynamic> _mockSafeRouteResponse() => {
        'success': true,
        'message': 'Safest route generated successfully.',
        'route': {
          'recommended_routes': AppMockData.recommendedRouteJson,
          'recent_routes': AppMockData.recentRoutesJson,
        },
      };

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

  Future<void> logout({
    required String email,
    required String password,
  }) async {
    if (ApiConfig.useMockApi) {
      await _mockDelay();
      return;
    }
    try {
      final response = await _dio.post(
        _path('/auth/logout'),
        data: _form({
          'email': email,
          'password': password,
        }),
      );
      _map(response);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
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
    if (ApiConfig.useMockApi) {
      await _mockDelay();
      final userId = await _storage.read(key: ApiConfig.storageKeyUserId);
      return UserPreferencesModel(
        id: '1',
        userId: userId ?? '1',
        shareLiveLocation: true,
        emergencyAlertsEnabled: true,
        pushNotificationsEnabled: true,
        emailNotificationsEnabled: false,
      );
    }

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
  }) {
    return _apiOrMock(
      () async {
        final payload = {
          'origin': {
            'location': {
              'latLng': {
                'latitude': originLat,
                'longitude': originLng,
              }
            }
          },
          'destination': {
            'location': {
              'latLng': {
                'latitude': destLat,
                'longitude': destLng,
              }
            }
          },
          'travelMode': 'WALK',
          'computeAlternativeRoutes': true,
          'languageCode': 'en-US',
          'units': 'METRIC',
        };

        final response = await _dio.post(
          _path('/routes/generate-safe-route'),
          options: Options(
            headers: {
              'Content-Type': 'application/json',
              'X-Goog-FieldMask':
                  'routes.duration,routes.distanceMeters,routes.polyline.encodedPolyline,routes.legs,routes.travelAdvisory,routes.routeLabels',
            },
          ),
          data: json.encode(payload),
        );
        return _map(response);
      },
      () async => _mockSafeRouteResponse(),
    );
  }

  // ─── Routes ─────────────────────────────────────────────────────────────────

  Future<List<RouteModel>> searchRoutes(String query) async {
    if (query.trim().length < 2) return [];
    if (query.toLowerCase().contains('xyz')) return [];

    return _apiOrMock(
      () async {
        final response = await _dio.get(
          _path('/routes/search'),
          queryParameters: {'q': query},
        );
        final map = _map(response);
        final list = map['routes'] as List<dynamic>? ?? [];
        return list
            .map((e) => RouteModel.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      },
      () async => AppMockData.searchRoutes,
    );
  }

  Future<RouteModel> getRouteDetail(String routeId) async {
    return _apiOrMock(
      () async {
        final response = await _dio.get(_path('/routes/$routeId'));
        final map = _map(response);
        return RouteModel.fromJson(
          Map<String, dynamic>.from((map['route'] ?? map) as Map),
        );
      },
      () async => AppMockData.routeDetail(routeId),
    );
  }

  Future<RouteModel> saveRoute(Map<String, dynamic> body) async {
    return _apiOrMock(
      () async {
        final response = await _dio.post(
          _path('/routes'),
          data: body,
          options: Options(
            headers: {'Content-Type': 'application/json'},
          ),
        );
        final map = _map(response);
        return RouteModel.fromJson(
          Map<String, dynamic>.from((map['route'] ?? map) as Map),
        );
      },
      () async => RouteModel.fromJson({
        'id': 'mock_saved',
        'route_name': body['routeName'] ?? 'Saved Route',
        'distance_km': body['distanceKm'],
        'estimated_time': body['formattedDuration'],
        'route_encoded_polyline': body['encodedPolyline'],
        'difficulty': body['difficulty'],
        'route_type': body['routeType'],
        'lighting': body['lighting'],
        'travel_mode': body['travelMode'],
        'estimated_calories': body['estimatedCalories'],
        'estimated_steps': body['estimatedSteps'],
        'avg_speed_kmh': body['averageSpeedKmh'],
        'safepoints': 17,
        'safety_score': 80,
        'is_secure': true,
        'start_latitude': body['start_latitude'],
        'start_longitude': body['start_longitude'],
        'end_latitude': body['end_latitude'],
        'end_longitude': body['end_longitude'],
      }),
    );
  }

  List<RouteModel> _mockRouteList() => [
        RouteModel(
          id: '1',
          name: 'Lakeside Perimeter',
          distanceKm: 3.2,
          durationMinutes: 24,
          tag: 'Popular',
          runnerCount: 12,
        ),
        RouteModel(
          id: '2',
          name: 'North Loop Patrol',
          distanceKm: 2.3,
          durationMinutes: 18,
          safePoints: 14,
          runnerCount: 23,
          saefraScore: 94,
          locationLabel: 'Central Park, NY',
          visibilityLabel: 'High Visibility Route',
        ),
        RouteModel(
          id: '3',
          name: 'River Trail Loop',
          distanceKm: 5.0,
          durationMinutes: 35,
          tag: 'Scenic',
          runnerCount: 8,
        ),
      ];

  RouteModel _mockRouteDetail(String id) => RouteModel(
        id: id,
        name: 'North Loop Patrol',
        distanceKm: 2.3,
        durationMinutes: 18,
        runnerCount: 23,
        safePoints: 14,
        saefraScore: 94,
        safetyScore: '94%',
        locationLabel: 'Central Park, NY',
        visibilityLabel: 'High Visibility Route',
        trafficLevel: 'Low',
        lightingLevel: 'High',
        communityRating: 4.8,
        isSecure: true,
      );

  // ─── Settings / emergency contacts (API-ready stubs) ────────────────────────

  Future<List<EmergencyContactModel>> getEmergencyContacts() async {
    return _apiOrMock(
      () async {
        final response = await _dio.get(_path('/emergency-contacts'));
        final map = _map(response);
        final list = map['contacts'] as List<dynamic>? ?? [];
        return list
            .map((e) => EmergencyContactModel.fromJson(
                  Map<String, dynamic>.from(e as Map),
                ))
            .toList();
      },
      () async => <EmergencyContactModel>[],
    );
  }

  Future<void> addEmergencyContact({
    required String name,
    required String phone,
  }) async {
    if (ApiConfig.useMockApi) {
      await _mockDelay();
      return;
    }
    try {
      final response = await _dio.post(
        _path('/emergency-contacts'),
        data: _form({'name': name, 'phone': phone}),
      );
      _map(response);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<void> removeEmergencyContact(String id) async {
    if (ApiConfig.useMockApi) {
      await _mockDelay();
      return;
    }
    try {
      final response = await _dio.delete(_path('/emergency-contacts/$id'));
      _map(response);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    if (ApiConfig.useMockApi) {
      await _mockDelay();
      return;
    }
    try {
      final response = await _dio.post(
        _path('/auth/change-password'),
        data: _form({
          'current_password': oldPassword,
          'password': newPassword,
          'password_confirmation': confirmPassword,
        }),
      );
      _map(response);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // ─── Community ──────────────────────────────────────────────────────────────

  List<CommunityRouteModel> _mockCommunityRoutes() => const [
        CommunityRouteModel(
          id: 'c1',
          name: 'Sunset Loop',
          location: 'Central Park, NY',
          distanceKm: 5.02,
          durationMinutes: 42,
          rating: 4.8,
          likeCount: 128,
          commentCount: 24,
          difficultyTag: 'Beginner',
          tags: ['Hill', 'Forest', 'Nature'],
          elevationGainM: 154,
          description:
              'A scenic loop through tree-lined paths with excellent lighting and steady foot traffic.',
        ),
        CommunityRouteModel(
          id: 'c2',
          name: 'Lakeside Perimeter',
          location: 'Hudson River',
          distanceKm: 3.2,
          durationMinutes: 24,
          rating: 4.6,
          likeCount: 86,
          commentCount: 11,
          difficultyTag: 'Easy',
          tags: ['Waterfront', 'Flat'],
          elevationGainM: 42,
        ),
        CommunityRouteModel(
          id: 'c3',
          name: 'North Loop Patrol',
          location: 'Brooklyn Bridge',
          distanceKm: 2.3,
          durationMinutes: 18,
          rating: 4.9,
          likeCount: 210,
          commentCount: 45,
          difficultyTag: 'Moderate',
          tags: ['Urban', 'Well-lit'],
          elevationGainM: 88,
        ),
      ];

  Future<List<CommunityRouteModel>> getPopularRoutes() async {
    return _apiOrMock(
      () async {
        final response = await _dio.get(_path('/community/routes/popular'));
        final map = _map(response);
        final list = map['routes'] as List<dynamic>? ?? [];
        return list
            .map((e) =>
                CommunityRouteModel.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      },
      () async => AppMockData.communityRoutes,
    );
  }

  Future<List<CommunityRouteModel>> getTopRatedRoutes() async {
    return _apiOrMock(
      () async {
        final response = await _dio.get(_path('/community/routes/top-rated'));
        final map = _map(response);
        final list = map['routes'] as List<dynamic>? ?? [];
        return list
            .map((e) =>
                CommunityRouteModel.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      },
      () async => AppMockData.communityRoutes.reversed.toList(),
    );
  }

  Future<CommunityRouteModel> getCommunityRouteDetail(String routeId) async {
    return _apiOrMock(
      () async {
        final response = await _dio.get(_path('/community/routes/$routeId'));
        final map = _map(response);
        return CommunityRouteModel.fromJson(
          Map<String, dynamic>.from((map['route'] ?? map) as Map),
        );
      },
      () async => AppMockData.communityRoutes.firstWhere(
        (r) => r.id == routeId,
        orElse: () => AppMockData.communityRoutes.first,
      ),
    );
  }

  Future<List<ReviewModel>> getRouteReviews(String routeId) async {
    return _apiOrMock(
      () async {
        final response =
            await _dio.get(_path('/community/routes/$routeId/reviews'));
        final map = _map(response);
        final list = map['reviews'] as List<dynamic>? ?? [];
        return list
            .map((e) => ReviewModel.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      },
      () async => AppMockData.routeReviews,
    );
  }

  Future<void> submitRouteReview({
    required String routeId,
    required double rating,
    required String comment,
  }) async {
    if (ApiConfig.useMockApi) {
      await _mockDelay();
      return;
    }
    try {
      await _dio.post(
        _path('/community/routes/$routeId/reviews'),
        data: _form({'rating': '$rating', 'comment': comment}),
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // ─── Activity ───────────────────────────────────────────────────────────────

  Future<ActivitySummaryModel> getActivitySummary(ActivityPeriod period) async {
    return _apiOrMock(
      () async {
        final response = await _dio.get(
          _path('/activity/summary'),
          queryParameters: {'period': period.name},
        );
        final map = _map(response);
        return ActivitySummaryModel.fromJson(
          Map<String, dynamic>.from((map['summary'] ?? map) as Map),
        );
      },
      () async => AppMockData.activitySummary(period),
    );
  }

  Future<List<RecentActivityModel>> getRecentActivities() async {
    return _apiOrMock(
      () async {
        final response = await _dio.get(_path('/activity/recent'));
        final map = _map(response);
        final list = map['activities'] as List<dynamic>? ?? [];
        return list
            .map((e) =>
                RecentActivityModel.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      },
      () async => AppMockData.recentActivities,
    );
  }

  Future<LifetimeStatsModel> getLifetimeStats() async {
    return _apiOrMock(
      () async {
        final response = await _dio.get(_path('/activity/lifetime'));
        final map = _map(response);
        return LifetimeStatsModel.fromJson(
          Map<String, dynamic>.from((map['lifetime'] ?? map) as Map),
        );
      },
      () async => AppMockData.lifetimeStats,
    );
  }

  // ─── Live run / SOS / reviews ───────────────────────────────────────────────

  Future<void> sendSos({
    String? routeId,
    required double latitude,
    required double longitude,
  }) async {
    if (ApiConfig.useMockApi) {
      await _mockDelay();
      return;
    }
    try {
      await _dio.post(
        _path('/sos/activate'),
        data: _form({
          if (routeId != null) 'route_id': routeId,
          'latitude': '$latitude',
          'longitude': '$longitude',
        }),
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<void> submitRunSummary(Map<String, dynamic> payload) async {
    if (ApiConfig.useMockApi) {
      await _mockDelay();
      return;
    }
    try {
      await _dio.post(_path('/runs/summary'), data: _form(payload));
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<void> submitRunReview({
    required String runId,
    required RunReviewFormModel form,
  }) async {
    if (ApiConfig.useMockApi) {
      await _mockDelay();
      return;
    }
    try {
      await _dio.post(
        _path('/runs/$runId/review'),
        data: _form(form.toJson()),
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

}
