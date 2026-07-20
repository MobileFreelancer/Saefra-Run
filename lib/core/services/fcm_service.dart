import 'dart:developer' as developer;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:saefra_run/core/services/api_service.dart';
import 'package:saefra_run/core/services/permission_service.dart';

/// Registers the device FCM token with the backend.
class FcmService {
  FcmService._();

  static final ApiService _api = ApiService();
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    try {
      await PermissionService.requestNotificationPermission();
      final messaging = FirebaseMessaging.instance;

      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (defaultTargetPlatform == TargetPlatform.iOS) {
        await messaging.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
      }

      final token = await messaging.getToken();
      if (token != null && token.isNotEmpty) {
        await syncToken(token);
      }

      messaging.onTokenRefresh.listen((token) {
        syncToken(token);
      });
    } catch (e, s) {
      developer.log('FCM initialize failed: $e', stackTrace: s);
    }
  }

  static Future<void> syncToken([String? token]) async {
    try {
      final resolved = token ?? await FirebaseMessaging.instance.getToken();
      if (resolved == null || resolved.isEmpty) return;
      await _api.updateFcmToken(resolved);
      developer.log('FCM token synced with backend');
    } catch (e, s) {
      developer.log('FCM token sync failed: $e', stackTrace: s);
    }
  }
}
