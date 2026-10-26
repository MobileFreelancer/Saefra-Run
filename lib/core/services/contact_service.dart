import 'package:flutter/foundation.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

class PickedContact {
  const PickedContact({required this.name, required this.phone});

  final String name;
  final String phone;
}

/// Reads device contacts with permission retry (asks a second time if first denied).
class ContactService extends ChangeNotifier {
  bool _isLoading = false;
  String? _statusMessage;

  bool get isLoading => _isLoading;
  String? get statusMessage => _statusMessage;

  Future<bool> _requestReadPermission() async {
    final status =
        await FlutterContacts.permissions.request(PermissionType.read);
    return status == PermissionStatus.granted ||
        status == PermissionStatus.limited;
  }

  /// First request, then optional second request if the first is denied.
  Future<bool> ensurePermission({bool allowSecondPrompt = true}) async {
    if (await FlutterContacts.permissions.has(PermissionType.read)) {
      _statusMessage = null;
      notifyListeners();
      return true;
    }

    if (await _requestReadPermission()) {
      _statusMessage = null;
      notifyListeners();
      return true;
    }

    if (!allowSecondPrompt) {
      _statusMessage =
          'Contacts permission is needed to pick an emergency contact.';
      notifyListeners();
      return false;
    }

    // Second attempt — user may have dismissed the first system sheet.
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (await _requestReadPermission()) {
      _statusMessage = null;
      notifyListeners();
      return true;
    }

    final status =
        await FlutterContacts.permissions.check(PermissionType.read);
    if (status == PermissionStatus.permanentlyDenied ||
        status == PermissionStatus.restricted) {
      _statusMessage =
          'Contacts access is blocked. Enable it in Settings to import contacts.';
    } else {
      _statusMessage =
          'Contacts permission is needed to pick an emergency contact.';
    }
    notifyListeners();
    return false;
  }

  Future<PickedContact?> pickFromDevice({bool allowSecondPrompt = true}) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (!await ensurePermission(allowSecondPrompt: allowSecondPrompt)) {
        return null;
      }

      final contact = await FlutterContacts.native.showPicker(
        properties: {ContactProperty.phone},
      );
      if (contact == null) return null;

      final name = (contact.displayName ?? '').trim();
      final phone = _primaryPhone(contact);
      if (name.isEmpty || phone.isEmpty) {
        _statusMessage = 'Selected contact has no usable phone number.';
        notifyListeners();
        return null;
      }

      _statusMessage = null;
      return PickedContact(name: name, phone: phone);
    } catch (e) {
      debugPrint('pickFromDevice failed: $e');
      _statusMessage = 'Could not open contacts. Please try again.';
      notifyListeners();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String _primaryPhone(Contact contact) {
    for (final phone in contact.phones) {
      final value = phone.number.trim();
      if (value.isNotEmpty) return value;
    }
    return '';
  }

  Future<void> openAppSettingsForContacts() async {
    await FlutterContacts.permissions.openSettings();
  }
}
