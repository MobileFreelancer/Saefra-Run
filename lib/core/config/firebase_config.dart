import 'package:firebase_core/firebase_core.dart';

/// Firebase bootstrap helpers.
class FirebaseConfig {
  FirebaseConfig._();

  static bool get isEnabled => Firebase.apps.isNotEmpty;

  static Future<void> initialize() async {
    if (Firebase.apps.isNotEmpty) return;
  }
}
