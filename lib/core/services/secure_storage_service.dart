import 'package:flutter_secure_storage/flutter_secure_storage.dart';

export 'package:flutter_secure_storage/flutter_secure_storage.dart'
    show FlutterSecureStorage;

/// Shared secure storage with Android-safe defaults.
///
/// `resetOnError` clears corrupted keystore entries instead of crashing
/// the app on some emulators/devices.
class SecureStorageService {
  SecureStorageService._();

  static const FlutterSecureStorage instance = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      resetOnError: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );
}
