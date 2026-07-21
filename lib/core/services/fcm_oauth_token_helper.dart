import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:googleapis_auth/auth_io.dart';

/// Generates OAuth access tokens for manual FCM HTTP v1 testing.
/// Uses [auth_io] only — no browser/web imports (safe on Android/iOS).
class FcmOAuthTokenHelper {
  FcmOAuthTokenHelper._();

  static const _serviceAccountAsset = 'assets/notifaction.json';

  static Future<void> generateAccessToken() async {
    final jsonString = await rootBundle.loadString(_serviceAccountAsset);

    final credentials = ServiceAccountCredentials.fromJson(
      json.decode(jsonString) as Map<String, dynamic>,
    );

    final client = await clientViaServiceAccount(
      credentials,
      ['https://www.googleapis.com/auth/firebase.messaging'],
    );

    final token = client.credentials.accessToken;
    developer.log('FCM OAuth access token: ${token.data}');
    debugPrint('FCM OAuth access token: ${token.data}');
    client.close();
  }
}
