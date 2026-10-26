import 'dart:developer' as developer;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:saefra_run/core/services/api_service.dart';
import 'package:saefra_run/core/services/fcm_oauth_token_helper.dart';
import 'package:saefra_run/core/services/permission_service.dart';
import 'package:saefra_run/core/services/secure_storage_service.dart';

import '../config/api_config.dart';

typedef PushReceivedCallback = void Function(RemoteMessage message);

/// Firebase Cloud Messaging — token sync and message handlers only.
/// System notifications are shown by FCM/OS (background/killed). No local plugin.
class FcmService {
  FcmService._();

  static final ApiService _api = ApiService();
  static bool _initialized = false;
  static bool _listenersAttached = false;
  static PushReceivedCallback? _onPushReceived;

  static const _nativeChannel = MethodChannel('com.saefra.run/notifications');

  static void setPushReceivedCallback(PushReceivedCallback? callback) {
    _onPushReceived = callback;
  }

  /// Register listeners and fetch token. Call from [main] after Firebase init.
  static Future<void> setup() async {
    if (_initialized) return;

    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.setAutoInitEnabled(true);

      await _attachMessageListeners(messaging);

      final token = await messaging.getToken();
      _logToken(token);
     /*FirebaseMessaging messaging = FirebaseMessaging.instance;
      String? apnsToken = await messaging.getAPNSToken();
      print("APNS Token: $apnsToken");
      String? fcmToken = await messaging.getToken();
      print("FCM Token: $fcmToken");
       */
      messaging.onTokenRefresh.listen((token) {
        _logToken(token, refreshed: true);
        syncToken(token);
      });

      _initialized = true;
      debugPrint('FCM messaging listeners ready');
    } catch (e, s) {
      developer.log('FCM setup failed: $e', stackTrace: s);
      debugPrint('FCM setup failed: $e');
    }
  }

  /// Backward-compatible alias — runs permission + token sync after first frame.
  static Future<void> initialize() => requestPermissionAndSync();

  /// Request OS permission (needs Activity) and sync token with backend.
  /// Call after the first frame when the user is logged in.
  static Future<void> requestPermissionAndSync() async {
    try {
      final granted = await PermissionService.requestNotificationPermission();
      debugPrint('Notification permission granted: $granted');

      final messaging = FirebaseMessaging.instance;

      if (defaultTargetPlatform == TargetPlatform.iOS) {
        final settings = await messaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
        debugPrint('FCM iOS auth: ${settings.authorizationStatus}');

        // iOS APNS token wait loop
        String? apnsToken;
        int retry = 0;
        while (apnsToken == null && retry < 10) {
          apnsToken = await messaging.getAPNSToken();
          if (apnsToken == null) {
            await Future.delayed(const Duration(seconds: 1));
            retry++;
          }
        }
        debugPrint('FCM APNS token: $apnsToken');

        await messaging.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
      } else if (defaultTargetPlatform == TargetPlatform.android) {
        final settings = await messaging.getNotificationSettings();
        debugPrint('FCM Android auth: ${settings.authorizationStatus}');
      }

      final token = await messaging.getToken();
      _logToken(token);
      if (token != null && token.isNotEmpty) {
        await syncToken(token);
      }

      debugPrint('FCM initialized successfully');
    } catch (e, s) {
      developer.log('FCM permission/sync failed: $e', stackTrace: s);
      debugPrint('FCM permission/sync failed: $e');
    }
  }

  static void _logToken(String? token, {bool refreshed = false}) {
    final label = refreshed ? 'FCM token refreshed' : 'FCM device token';
    developer.log('$label: $token');
    debugPrint('$label: $token');
  }

  static Future<void> _attachMessageListeners(FirebaseMessaging messaging) async {
    if (_listenersAttached) return;
    _listenersAttached = true;

    FirebaseMessaging.onMessage.listen((message) {
      developer.log(
        'FCM foreground message: id=${message.messageId} '
        'title=${message.notification?.title} body=${message.notification?.body} '
        'data=${message.data}',
      );
      debugPrint(
        'FCM foreground: ${message.notification?.title ?? message.data['title']}',
      );

      // Trigger native system notification for foreground
      if (message.notification != null) {
        _nativeChannel.invokeMethod('showNotification', {
          'title': message.notification?.title,
          'body': message.notification?.body,
        });
      }

      _onPushReceived?.call(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      developer.log('FCM opened from notification: ${message.messageId}');
      debugPrint('FCM opened from notification');
      _onPushReceived?.call(message);
    });

    final initial = await messaging.getInitialMessage();
    if (initial != null) {
      developer.log('FCM initial message: ${initial.messageId}');
      debugPrint('FCM initial message received');
      _onPushReceived?.call(initial);
    }
  }

  static Future<void> syncToken([String? token]) async {
    try {
      final storage = SecureStorageService.instance;
      final accessToken = await storage.read(key: ApiConfig.storageKeyAccessToken);

      if (accessToken == null || accessToken.isEmpty) {
        developer.log('FCM token sync skipped: No active session');
        return;
      }

      final resolved = token ?? await FirebaseMessaging.instance.getToken();
      if (resolved == null || resolved.isEmpty) return;
      await _api.updateFcmToken(resolved);
      developer.log('FCM token synced with backend');
      debugPrint('FCM token synced with backend');
    } catch (e, s) {
      developer.log('FCM token sync failed: $e', stackTrace: s);
      debugPrint('FCM token sync failed: $e');
    }
  }
  /// Generates a short-lived OAuth token for manual FCM HTTP v1 curl tests.
  static Future<void> generateAccessToken() =>
      FcmOAuthTokenHelper.generateAccessToken();
}
