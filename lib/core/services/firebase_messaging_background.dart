import 'dart:developer' as developer;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';
import 'package:saefra_run/firebase_options.dart';

/// Handles FCM when the app is backgrounded or killed.
/// Notification payload is displayed by the OS — no local notification plugin.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  developer.log(
    'FCM background message: id=${message.messageId} '
    'title=${message.notification?.title} data=${message.data}',
  );
  debugPrint(
    'FCM background: ${message.notification?.title ?? message.data['title']}',
  );
}
