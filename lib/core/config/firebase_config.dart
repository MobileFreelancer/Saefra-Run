/// Future Firebase integration placeholder.
///
/// When the backend and Firebase project are ready:
/// 1. Add `firebase_core`, `firebase_auth`, `firebase_messaging` to pubspec.yaml
/// 2. Run `flutterfire configure`
/// 3. Uncomment and implement the methods below
/// 4. Call [FirebaseConfig.initialize] from main.dart before runApp
///
/// This file intentionally has no Firebase dependencies so the app builds
/// without a Firebase project configured.
class FirebaseConfig {
  FirebaseConfig._();

  static bool get isEnabled => false;

  static Future<void> initialize() async {
    // await Firebase.initializeApp(
    //   options: DefaultFirebaseOptions.currentPlatform,
    // );
  }

  static Future<void> requestNotificationPermission() async {
    // final messaging = FirebaseMessaging.instance;
    // await messaging.requestPermission();
  }
}
