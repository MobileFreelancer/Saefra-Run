import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  PermissionService._();

  /// Request Location Permission
  static Future<bool> requestLocationPermission() async {
    var status = await Permission.location.status;

    if (status.isGranted) {
      return true;
    }

    if (status.isDenied) {
      status = await Permission.location.request();
      return status.isGranted;
    }

    if (status.isPermanentlyDenied) {
      await openAppSettings();
      return false;
    }

    return false;
  }

  /// Check Location Permission
  static Future<bool> isLocationPermissionGranted() async {
    return await Permission.location.isGranted;
  }

  /// Request Notification Permission
  static Future<bool> requestNotificationPermission() async {
    var status = await Permission.notification.status;

    if (status.isGranted) {
      return true;
    }

    if (status.isDenied) {
      status = await Permission.notification.request();
      return status.isGranted;
    }

    if (status.isPermanentlyDenied) {
      await openAppSettings();
      return false;
    }

    return false;
  }

  /// Check Notification Permission
  static Future<bool> isNotificationPermissionGranted() async {
    return await Permission.notification.isGranted;
  }

  /// Open App Settings
  static Future<void> openSettings() async {
    await openAppSettings();
  }
}