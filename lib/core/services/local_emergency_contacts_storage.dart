import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:saefra_run/core/config/api_config.dart';
import 'package:saefra_run/core/models/emergency_contact_model.dart';
import 'package:saefra_run/core/services/secure_storage_service.dart';

/// Persists emergency contacts picked from the device address book.
class LocalEmergencyContactsStorage {
  LocalEmergencyContactsStorage._();

  static final _storage = SecureStorageService.instance;

  static Future<List<EmergencyContactModel>> read() async {
    try {
      final raw = await _storage.read(
        key: ApiConfig.storageKeyEmergencyContacts,
      );
      if (raw == null || raw.isEmpty) return [];

      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];

      return decoded
          .whereType<Map>()
          .map(
            (item) => EmergencyContactModel(
              id: '${item['id'] ?? ''}',
              name: item['name'] as String? ?? '',
              phone: item['phone'] as String? ?? '',
            ),
          )
          .where((c) => c.name.isNotEmpty && c.phone.isNotEmpty)
          .toList();
    } catch (e) {
      debugPrint('LocalEmergencyContactsStorage.read failed: $e');
      return [];
    }
  }

  static Future<void> write(List<EmergencyContactModel> contacts) async {
    final payload = jsonEncode(contacts.map((c) => c.toJson()).toList());
    await _storage.write(
      key: ApiConfig.storageKeyEmergencyContacts,
      value: payload,
    );
  }
}
