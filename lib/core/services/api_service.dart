import 'dart:io';

import 'package:dio/dio.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:saefra_run/core/config/api_config.dart';
import 'package:saefra_run/core/models/activity_model.dart';
import 'package:saefra_run/core/models/auth_response_model.dart';
import 'package:saefra_run/core/models/community_route_list_result.dart';
import 'package:saefra_run/core/models/community_route_model.dart';
import 'package:saefra_run/core/models/community_routes_result.dart';
import 'package:saefra_run/core/models/emergency_contact_model.dart';
import 'package:saefra_run/core/models/notification_model.dart';
import 'package:saefra_run/core/models/onboarding_api_result.dart';
import 'package:saefra_run/core/models/review_model.dart';
import 'package:saefra_run/core/models/route_review_list_result.dart';
import 'package:saefra_run/core/models/route_model.dart';
import 'package:saefra_run/core/models/run_review_form_model.dart';
import 'package:saefra_run/core/models/sos_response_model.dart';
import 'package:saefra_run/core/models/user_model.dart';
import 'package:saefra_run/core/services/api_exception.dart';
import 'package:saefra_run/core/services/secure_storage_service.dart';
import 'package:saefra_run/core/utils/api_response_parser.dart';
import 'package:saefra_run/core/utils/formatters.dart';
import 'dart:developer' as developer;
import '../models/onboarding_model.dart';
import '../models/user_preferences_model.dart';
import '../utils/api_field_mapper.dart';
import '../utils/app_loader.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal() {
    _setupDio();
  }

  static void Function()? onUnauthorized;

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

          final path = response.requestOptions.path;
          final isAuthRoute = path.contains('/auth/login') ||
              path.contains('/auth/register') ||
              path.contains('/auth/social-login');
          if (response.statusCode == 401 && !isAuthRoute) {
            onUnauthorized?.call();
          }

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

          final path = e.requestOptions.path;
          final isAuthRoute = path.contains('/auth/login') ||
              path.contains('/auth/register') ||
              path.contains('/auth/social-login');
          if (e.response?.statusCode == 401 && !isAuthRoute) {
            onUnauthorized?.call();
          }

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

  // ─── Auth ───────────────────────────────────────────────────────────────────

  Future<AuthResponseModel> login({
    required String email,
    required String password,
  }) async {
    AppLoader.show();
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

  Future<AuthResponseModel> socialLogin({
    required String email,
    required String uuid,
    required String provider,
  }) async {
    AppLoader.show();
    try {
      final response = await _dio.post(
        _path('/auth/social-login'),
        data: _form({
          'email': email,
          'uuid': uuid,
          'provider': provider,
        }),
      );
      AppLoader.hide();
      return AuthResponseModel.fromJson(_map(response));
    } on DioException catch (e) {
      AppLoader.hide();
      throw _handleDioError(e);
    }
  }

  Future<OnboardingApiResult> getOnboarding() async {
    try {
      final response = await _dio.get(_path('/onboarding'));
      return OnboardingApiResult.fromResponse(_map(response));
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<OnboardingApiResult> updateOnboarding(OnboardingModel onboarding) async {
    try {
      final response = await _dio.post(
        _path('/onboarding'),
        data: _form(ApiFieldMapper.onboardingFormFromModel(onboarding)),
      );
      return OnboardingApiResult.fromResponse(_map(response));
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<AuthResponseModel> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String passwordConfirmation,
    required String gender,
    required String birthdate,
    required String visitReason,
    required String runPreference,
  }) async {
    AppLoader.show();
    try {
      final payload = <String, dynamic>{
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
        'gender': gender,
        'visit_reason': visitReason,
        'run_preference': runPreference,
      };
      if (birthdate.trim().isNotEmpty) {
        payload['birthdate'] = birthdate.trim();
      }

      final response = await _dio.post(
        _path('/auth/register'),
        data: _form(payload),
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
      firstName: ApiFieldMapper.formString(
        fields,
        'first_name',
        fallback: email.split('@').first,
      ),
      lastName: ApiFieldMapper.formString(fields, 'last_name', fallback: 'User'),
      email: ApiFieldMapper.formString(fields, 'email'),
      password: ApiFieldMapper.formString(fields, 'password'),
      passwordConfirmation:
          ApiFieldMapper.formString(fields, 'password_confirmation'),
      gender: ApiFieldMapper.formString(fields, 'gender'),
      birthdate: ApiFieldMapper.formString(fields, 'birthdate'),
      visitReason: ApiFieldMapper.formString(fields, 'visit_reason'),
      runPreference: ApiFieldMapper.formString(fields, 'run_preference'),
    );
  }

  Future<String> forgotPassword({required String email}) async {
    AppLoader.show();
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
    try {
      final response = await _dio.post(
        _path('/auth/verify-otp'),
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


  Future<UserModel> getCurrentUser() async {
    try {
      final response = await _dio.get(_path('/profile'));
      final map = _map(response);
      final payload = ApiResponseParser.payload(map);
      return UserModel.fromJson(ApiResponseParser.userFromPayload(payload));
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<UserModel> updateProfile({
    required String gender,
    required String birthdate,
    required String firstName,
    required String lastName,
    required String mobileNumber,
    String? profileImagePath,
  }) async {
    try {
      final Map<String, dynamic> dataMap = {
        'first_name': firstName,
        'last_name': lastName,
        'phone': mobileNumber,
        'gender': gender,
      };

      if (birthdate.trim().isNotEmpty) {
        dataMap['birthdate'] = _formatProfileBirthdate(birthdate.trim());
      }

      if (profileImagePath != null && profileImagePath.isNotEmpty) {
        dataMap['profile_image'] = await MultipartFile.fromFile(
          profileImagePath,
          filename: profileImagePath.split('/').last,
        );
      }

      final response = await _dio.post(
        _path('/profile'),
        data: _form(dataMap),
      );
      final map = _map(response);
      final payload = ApiResponseParser.payload(map);
      return UserModel.fromJson(ApiResponseParser.userFromPayload(payload));
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  String _formatProfileBirthdate(String birthdate) {
    DateTime parsed;
    if (birthdate.contains('.')) {
      final parts = birthdate.split('.');
      parsed = DateTime(
        int.parse(parts[2]),
        int.parse(parts[1]),
        int.parse(parts[0]),
      );
    } else if (birthdate.contains('-') &&
        birthdate.split('-').first.length == 4) {
      parsed = DateTime.parse(birthdate);
    } else if (birthdate.contains('-')) {
      final parts = birthdate.split('-');
      parsed = DateTime(
        int.parse(parts[2]),
        int.parse(parts[0]),
        int.parse(parts[1]),
      );
    } else {
      parsed = DateTime.parse(birthdate);
    }

    return DateFormat('yyyy-MM-dd').format(parsed);
  }

  Future<UserModel> updateProfileFromOnboarding(OnboardingModel onboarding) {
    final fields = ApiFieldMapper.profileFormFromOnboarding(onboarding);
    return updateProfile(
      gender: ApiFieldMapper.formString(fields, 'gender'),
      birthdate: ApiFieldMapper.formString(fields, 'birthdate'),
      firstName: ApiFieldMapper.formString(fields, 'first_name'),
      lastName: ApiFieldMapper.formString(fields, 'last_name'),
      mobileNumber: ApiFieldMapper.formString(fields, 'phone'),
    );
  }



  Future<UserPreferencesModel> getPreferences() async {
    try {
      final response = await _dio.get(_path('/preferences'));
      final map = _map(response);
      final payload = ApiResponseParser.payload(map);
      return UserPreferencesModel.fromJson(
        ApiResponseParser.asMap(payload['preferences']),
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
    await updateOnboarding(onboarding);
  }

  Future<Map<String, dynamic>> generateSafeRoute({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
  }) async {
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
  }


  Future<List<RouteModel>> searchRoutes(String query) async {
    if (query.trim().length < 2) return [];

    final response = await _dio.get(
      _path('/routes/search'),
      queryParameters: {'q': query},
    );
    final map = _map(response);
    final list = map['routes'] as List<dynamic>? ?? [];
    return list
        .map((e) => RouteModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<RouteModel> getRouteDetail(String routeId) async {
    final response = await _dio.get(_path('/routes/$routeId'));
    final map = _map(response);
    final payload = ApiResponseParser.payload(map);
    return RouteModel.fromJson(
      Map<String, dynamic>.from((payload['route'] ?? payload) as Map),
    );
  }

  Future<RouteModel> saveRoute(Map<String, dynamic> body) async {
    final response = await _dio.post(
      _path('/routes'),
      data: body,
      options: Options(
        headers: {'Content-Type': 'application/json'},
      ),
    );
    final map = _map(response);
    final payload = ApiResponseParser.payload(map);
    return RouteModel.fromJson(
      Map<String, dynamic>.from((payload['route'] ?? payload) as Map),
    );
  }

  // ─── Settings / emergency contacts ──────────────────────────────────────────

  List<EmergencyContactModel> _parseEmergencyContactsList(dynamic raw) {
    if (raw is List) {
      return raw
          .map(
            (e) => EmergencyContactModel.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList();
    }
    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);
      for (final key in ['contacts', 'emergency_contacts', 'data']) {
        final value = map[key];
        if (value is List) {
          return _parseEmergencyContactsList(value);
        }
      }
      if (map.containsKey('id') || map.containsKey('contact_id')) {
        return [EmergencyContactModel.fromJson(map)];
      }
    }
    return [];
  }

  Future<List<EmergencyContactModel>> getEmergencyContacts() async {
    try {
      final response = await _dio.get(_path('/get-emergency-contacts'));
      final map = _map(response);
      final payload = ApiResponseParser.payload(map);
      final list = payload['contacts'] ??
          payload['emergency_contacts'] ??
          (map['data'] is List ? map['data'] : null);
      return _parseEmergencyContactsList(list ?? payload);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<EmergencyContactModel> addEmergencyContact({
    required String name,
    required String phone,
    String? imagePath,
  }) async {
    try {
      final fields = <String, dynamic>{
        'name': name,
        'phone': phone,
      };

      if (imagePath != null && imagePath.isNotEmpty) {
        final file = File(imagePath);
        if (await file.exists()) {
          final fileName = imagePath.split('/').last;
          fields['image'] = await MultipartFile.fromFile(
            imagePath,
            filename: fileName,
          );
        }
      }

      final response = await _dio.post(
        _path('/add-emergency-contacts'),
        data: FormData.fromMap(fields),
      );
      final map = _map(response);
      final payload = ApiResponseParser.payload(map);
      final contactJson = payload['contact'] ??
          payload['emergency_contact'] ??
          (payload.containsKey('id') || payload.containsKey('contact_id')
              ? payload
              : null);
      if (contactJson is Map) {
        return EmergencyContactModel.fromJson(
          Map<String, dynamic>.from(contactJson),
        );
      }
      return EmergencyContactModel(
        id: '${payload['id'] ?? ''}',
        name: name,
        phone: phone,
        imageUrl: payload['image'] as String?,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<void> removeEmergencyContact(String id) async {
    try {
      final response = await _dio.delete(
        _path('/delete-emergency-contacts/$id'),
        queryParameters: {'id': id},
      );
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

  Future<CommunityRoutesResult> getCommunityRoutes({
    int page = 1,
    int perPage = 20,
    String? search,
  }) async {
    try {
      final queryParameters = <String, dynamic>{
        'page': page,
        'perPage': perPage,
      };
      final query = search?.trim();
      if (query != null && query.isNotEmpty) {
        queryParameters['search'] = query;
      }

      final response = await _dio.post(
        _path('/community-routes'),
        queryParameters: queryParameters,
      );
      final map = _map(response);
      final payload = ApiResponseParser.payload(map);
      return CommunityRoutesResult.fromPayload(
        payload,
        page: page,
        perPage: perPage,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<CommunityRouteListResult> getPopularRoutesList({
    int page = 1,
    int perPage = 20,
    String? search,
  }) async {
    return _fetchCommunityRouteList(
      endpoint: '/popular-routes-list',
      page: page,
      perPage: perPage,
      search: search,
    );
  }

  Future<CommunityRouteListResult> getRecentRoutesList({
    int page = 1,
    int perPage = 20,
    String? search,
  }) async {
    return _fetchCommunityRouteList(
      endpoint: '/recent-routes-list',
      page: page,
      perPage: perPage,
      search: search,
    );
  }

  Future<CommunityRouteListResult> _fetchCommunityRouteList({
    required String endpoint,
    required int page,
    required int perPage,
    String? search,
  }) async {
    try {
      final queryParameters = <String, dynamic>{
        'page': page,
        'perPage': perPage,
      };
      final query = search?.trim();
      if (query != null && query.isNotEmpty) {
        queryParameters['search'] = query;
      }

      final response = await _dio.post(
        _path(endpoint),
        queryParameters: queryParameters,
      );
      final map = _map(response);
      final payload = ApiResponseParser.payload(map);
      return CommunityRouteListResult.fromPayload(
        payload,
        page: page,
        perPage: perPage,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @Deprecated('Use getCommunityRoutes instead')
  Future<List<CommunityRouteModel>> getPopularRoutes() async {
    final response = await _dio.get(_path('/community/routes/popular'));
    final map = _map(response);
    final payload = ApiResponseParser.payload(map);
    final list = payload['routes'] as List<dynamic>? ?? [];
    return list
        .map((e) =>
            CommunityRouteModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<List<CommunityRouteModel>> getTopRatedRoutes() async {
    final response = await _dio.get(_path('/community/routes/top-rated'));
    final map = _map(response);
    final payload = ApiResponseParser.payload(map);
    final list = payload['routes'] as List<dynamic>? ?? [];
    return list
        .map((e) =>
            CommunityRouteModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<CommunityRouteModel> getCommunityRouteDetail(String routeId) async {
    final response = await _dio.get(_path('/community/routes/$routeId'));
    final map = _map(response);
    final payload = ApiResponseParser.payload(map);
    return CommunityRouteModel.fromJson(
      Map<String, dynamic>.from((payload['route'] ?? payload) as Map),
    );
  }

  Future<RouteReviewListResult> getRouteReviewList({
    required String routeId,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final response = await _dio.post(
        _path('/route-review-list'),
        queryParameters: {
          'route_id': routeId,
          'page': page,
          'perPage': perPage,
        },
      );
      final map = _map(response);
      final payload = ApiResponseParser.payload(map);
      return RouteReviewListResult.fromPayload(
        payload,
        page: page,
        perPage: perPage,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @Deprecated('Use getRouteReviewList instead')
  Future<List<ReviewModel>> getRouteReviews(String routeId) async {
    final result = await getRouteReviewList(routeId: routeId);
    return result.reviews;
  }

  /// POST /api/v1/route-review — one review per user per route.
  Future<void> submitRouteReview({
    required String routeId,
    required double rating,
    required String comment,
    String? runId,
  }) async {
    try {
      final fields = <String, dynamic>{
        'route_id': routeId,
        'overall_rating': rating.round(),
        'comment': comment.trim(),
      };
      if (runId != null && runId.trim().isNotEmpty) {
        fields['run_id'] = runId.trim();
      }

      final response = await _dio.post(
        _path('/route-review'),
        data: _form(fields),
      );
      _map(response);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// POST /api/v1/contact-us
  Future<void> submitContactUs({
    required String name,
    required String email,
    required String message,
  }) async {
    try {
      final response = await _dio.post(
        _path('/contact-us'),
        queryParameters: {
          'name': name.trim(),
          'email': email.trim(),
          'message': message.trim(),
        },
      );
      _map(response);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // ─── Activity ───────────────────────────────────────────────────────────────

  Future<ActivityDashboardResult> getActivityDashboard() async {
    try {
      final response = await _dio.get(_path('/activity-dashboard'));
      final map = _map(response);
      final payload = ApiResponseParser.payload(map);
      return ActivityDashboardResult.fromPayload(payload);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @Deprecated('Use getActivityDashboard instead')
  Future<ActivitySummaryModel> getActivitySummary(ActivityPeriod period) async {
    final response = await _dio.get(
      _path('/activity/summary'),
      queryParameters: {'period': period.name},
    );
    final map = _map(response);
    final payload = ApiResponseParser.payload(map);
    return ActivitySummaryModel.fromJson(
      Map<String, dynamic>.from((payload['summary'] ?? payload) as Map),
    );
  }

  Future<List<RecentActivityModel>> getRecentActivities() async {
    final response = await _dio.get(_path('/activity/recent'));
    final map = _map(response);
    final payload = ApiResponseParser.payload(map);
    final list = payload['activities'] as List<dynamic>? ?? [];
    return list
        .map((e) =>
            RecentActivityModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<LifetimeStatsModel> getLifetimeStats() async {
    final response = await _dio.get(_path('/activity/lifetime'));
    final map = _map(response);
    final payload = ApiResponseParser.payload(map);
    return LifetimeStatsModel.fromJson(
      Map<String, dynamic>.from((payload['lifetime'] ?? payload) as Map),
    );
  }

  // ─── Live run / SOS / reviews ───────────────────────────────────────────────

  Future<SosActivateResponse> activateSos({
    double? latitude,
    double? longitude,
    String? addressLink,
  }) async {
    try {
      final fields = <String, dynamic>{};
      if (latitude != null) fields['latitude'] = latitude;
      if (longitude != null) fields['longitude'] = longitude;
      if (addressLink != null && addressLink.trim().isNotEmpty) {
        fields['address_link'] = addressLink.trim();
      }

      final response = await _dio.post(
        _path('/sos-activate'),
        data: _form(fields),
      );
      final map = _map(response);
      return SosActivateResponse.fromApiMap(map);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<SosCancelResponse> cancelSos() async {
    try {
      final response = await _dio.post(
        _path('/sos-cancel'),
        data: _form({}),
      );
      final map = _map(response);
      return SosCancelResponse.fromApiMap(map);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<void> submitRunSummary(Map<String, dynamic> payload) async {
    try {
      await _dio.post(_path('/runs/summary'), data: _form(payload));
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// POST /api/v1/route-review
  Future<void> submitRunReview({
    String? runId,
    required String routeId,
    required RunReviewFormModel form,
  }) async {
    try {
      final fields = form.toApiFields(routeId: routeId, runId: runId);
      final formData = FormData.fromMap(fields);

      for (final imagePath in form.imagePaths) {
        if (imagePath.isEmpty) continue;
        final file = File(imagePath);
        if (!await file.exists()) continue;
        formData.files.add(
          MapEntry(
            'route_image[]',
            await MultipartFile.fromFile(
              imagePath,
              filename: imagePath.split('/').last,
            ),
          ),
        );
      }

      final response = await _dio.post(
        _path('/route-review'),
        data: formData,
      );
      _map(response);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  String _apiDateTime(DateTime value) =>
      DateFormat('yyyy-MM-dd HH:mm:ss').format(value);

  String _parseRunId(Map<String, dynamic> payload) {
    final runId = payload['run_id']?.toString() ??
        payload['runId']?.toString() ??
        payload['id']?.toString();
    if (runId == null || runId.isEmpty) {
      throw const ApiException('Run ID missing from server response.');
    }
    return runId;
  }

  /// POST /api/v1/run-start
  Future<String> startRunSession({
    required String routeId,
    required double latitude,
    required double longitude,
    DateTime? startedAt,
  }) async {
    try {
      final response = await _dio.post(
        _path('/run-start'),
        data: _form({
          'route_id': routeId,
          'latitude': latitude,
          'longitude': longitude,
          'started_at': _apiDateTime(startedAt ?? DateTime.now()),
        }),
      );
      final map = _map(response);
      final payload = ApiResponseParser.payload(map);
      return _parseRunId(payload);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// POST /api/v1/run-update
  Future<void> updateRunSession({
    required String runId,
    required double latitude,
    required double longitude,
    required double distance,
    required int duration,
    required double speed,
    required String pace,
    required int steps,
    DateTime? timestamp,
  }) async {
    try {
      await _dio.post(
        _path('/run-update'),
        data: _form({
          'run_id': runId,
          'latitude': latitude,
          'longitude': longitude,
          'timestamp': _apiDateTime(timestamp ?? DateTime.now()),
          'distance': distance,
          'duration': duration,
          'speed': speed,
          'pace': pace,
          'steps': steps,
        }),
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// POST /api/v1/run-pause
  Future<void> pauseRunSession({required String runId}) async {
    try {
      await _dio.post(
        _path('/run-pause'),
        data: _form({'run_id': runId}),
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// POST /api/v1/run-resume
  Future<void> resumeRunSession({required String runId}) async {
    try {
      await _dio.post(
        _path('/run-resume'),
        data: _form({'run_id': runId}),
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// POST /api/v1/run-finish
  Future<void> finishRunSession({
    required String runId,
    required double latitude,
    required double longitude,
    required String polyline,
    DateTime? endedAt,
  }) async {
    try {
      await _dio.post(
        _path('/run-finish'),
        data: _form({
          'run_id': runId,
          'ended_at': _apiDateTime(endedAt ?? DateTime.now()),
          'polyline': polyline,
          'latitude': latitude,
          'longitude': longitude,
        }),
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// GET /api/v1/run-summary/{run_id}
  Future<Map<String, dynamic>> getRunSummary(String runId) async {
    try {
      final response = await _dio.get(
        _path('/run-summary/$runId'),
        queryParameters: {'run_id': runId},
      );
      final map = _map(response);
      return ApiResponseParser.payload(map);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// POST /api/v1/run-feeling
  Future<void> submitRunFeeling({
    required String runId,
    required String runFeeling,
  }) async {
    try {
      final response = await _dio.post(
        _path('/run-feeling'),
        data: _form({
          'run_id': runId,
          'run_feeling': runFeeling,
        }),
      );
      _map(response);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // ─── Notifications / FCM ───────────────────────────────────────────────────

  List<AppNotificationModel> _parseNotificationsList(dynamic raw) {
    if (raw is List) {
      return raw
          .map(
            (e) => AppNotificationModel.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList();
    }
    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);
      for (final key in ['notifications', 'data', 'items']) {
        final value = map[key];
        if (value is List) return _parseNotificationsList(value);
      }
    }
    return [];
  }

  Future<void> updateFcmToken(String fcmToken) async {
    try {
      await _dio.post(
        _path('/update-fcm-token'),
        data: _form({'fcm_token': fcmToken}),
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<NotificationListResult> getNotifications({
    String? category,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final fields = <String, dynamic>{
        'page': page,
        'perPage': perPage,
      };
      if (category != null && category.trim().isNotEmpty) {
        fields['category'] = category.trim();
      }

      final response = await _dio.post(
        _path('/get-notifications'),
        data: _form(fields),
      );
      final map = _map(response);
      final payload = ApiResponseParser.payload(map);
      final list = _parseNotificationsList(
        payload['notifications'] ?? payload,
      );

      return NotificationListResult(
        notifications: list,
        currentPage: page,
        hasMore: list.length >= perPage,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<AppNotificationModel> markNotificationRead(String id) async {
    try {
      final response = await _dio.post(
        _path('/read-notification/$id'),
        queryParameters: {'id': id},
      );
      final map = _map(response);
      final payload = ApiResponseParser.payload(map);
      if (payload.containsKey('id')) {
        return AppNotificationModel.fromJson(payload);
      }
      return AppNotificationModel(
        id: id,
        title: '',
        message: '',
        isRead: true,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<void> deleteNotification(String id) async {
    try {
      await _dio.delete(
        _path('/delete-notification/$id'),
        queryParameters: {'id': id},
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<void> clearAllNotifications() async {
    try {
      await _dio.delete(_path('/clear-all-notifications'));
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
}
