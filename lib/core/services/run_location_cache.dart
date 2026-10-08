import 'package:flutter/foundation.dart';
import 'package:saefra_run/core/services/secure_storage_service.dart';

/// Persists reverse-geocoded city/state for completed runs so Activity can
/// show the run's actual place even when the dashboard returns a stale
/// catalog `location` string.
class RunLocationCache {
  RunLocationCache._();

  static String _key(String runId) => 'run_location_$runId';

  static Future<void> save(String runId, String cityState) async {
    final id = runId.trim();
    final value = cityState.trim();
    if (id.isEmpty || value.isEmpty) return;
    try {
      await SecureStorageService.instance.write(key: _key(id), value: value);
      debugPrint('[RunLocationCache] Saved run $id → $value');
    } catch (e) {
      debugPrint('[RunLocationCache] Save failed for $id: $e');
    }
  }

  static Future<String?> read(String runId) async {
    final id = runId.trim();
    if (id.isEmpty) return null;
    try {
      final value = await SecureStorageService.instance.read(key: _key(id));
      if (value == null || value.trim().isEmpty) return null;
      return value.trim();
    } catch (e) {
      debugPrint('[RunLocationCache] Read failed for $id: $e');
      return null;
    }
  }
}
