import 'package:flutter/foundation.dart';
import 'package:saefra_run/core/models/emergency_contact_model.dart';
import 'package:saefra_run/core/models/user_model.dart';
import 'package:saefra_run/core/models/user_preferences_model.dart';
import 'package:saefra_run/core/services/api_service.dart';
import 'package:saefra_run/core/services/auth_service.dart';
import 'package:saefra_run/core/services/local_emergency_contacts_storage.dart';

class SettingsService extends ChangeNotifier {
  SettingsService(this._auth);

  final AuthService _auth;
  final ApiService _api = ApiService();

  UserPreferencesModel? _preferences;
  List<EmergencyContactModel> _contacts = [];
  bool _isLoading = false;
  String? _error;

  bool _liveTracking = true;
  bool _emergencyAlerts = true;
  bool _pushNotifications = true;
  bool _emailNotifications = false;
  bool _smsNotifications = false;

  String _firstName = '';
  String _lastName = '';
  String _email = '';
  String _phone = '';

  UserPreferencesModel? get preferences => _preferences;
  List<EmergencyContactModel> get contacts => _contacts;
  bool get isLoading => _isLoading;
  String? get error => _error;

  bool get liveTracking => _liveTracking;
  bool get emergencyAlerts => _emergencyAlerts;
  bool get pushNotifications => _pushNotifications;
  bool get emailNotifications => _emailNotifications;
  bool get smsNotifications => _smsNotifications;

  String get firstName => _firstName;
  String get lastName => _lastName;
  String get email => _email;
  String get phone => _phone;

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = _auth.currentUser ?? await _api.getCurrentUser();
      _hydrateProfile(user);
      _preferences = await _api.getPreferences();
      _liveTracking = _preferences?.shareLiveLocation ?? _liveTracking;
      _emergencyAlerts =
          _preferences?.emergencyAlertsEnabled ?? _emergencyAlerts;
      _pushNotifications =
          _preferences?.pushNotificationsEnabled ?? _pushNotifications;
      _emailNotifications =
          _preferences?.emailNotificationsEnabled ?? _emailNotifications;

      final apiContacts = await _api.getEmergencyContacts();
      final localContacts = await LocalEmergencyContactsStorage.read();
      _contacts = _mergeContacts(apiContacts, localContacts);
    } catch (e) {
      _error = e.toString();
      _contacts = await LocalEmergencyContactsStorage.read();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<EmergencyContactModel> _mergeContacts(
    List<EmergencyContactModel> apiContacts,
    List<EmergencyContactModel> localContacts,
  ) {
    if (apiContacts.isNotEmpty) return apiContacts;
    return localContacts;
  }

  void _hydrateProfile(UserModel user) {
    _email = user.email ?? '';
    _phone = user.phoneNumber ?? '';
    final name = user.fullName ?? '';
    final parts = name.split(' ');
    _firstName = parts.isNotEmpty ? parts.first : '';
    _lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';
  }

  void updateProfileFields({
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
  }) {
    if (firstName != null) _firstName = firstName;
    if (lastName != null) _lastName = lastName;
    if (email != null) _email = email;
    if (phone != null) _phone = phone;
    notifyListeners();
  }

  void setLiveTracking(bool v) {
    _liveTracking = v;
    notifyListeners();
  }

  void setEmergencyAlerts(bool v) {
    _emergencyAlerts = v;
    notifyListeners();
  }

  void setPushNotifications(bool v) {
    _pushNotifications = v;
    notifyListeners();
  }

  void setEmailNotifications(bool v) {
    _emailNotifications = v;
    notifyListeners();
  }

  void setSmsNotifications(bool v) {
    _smsNotifications = v;
    notifyListeners();
  }

  Future<bool> saveProfile() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _api.updateProfile(
        gender: _auth.currentUser?.gender ?? 'male',
        birthdate: '01-01-1990',
      );
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> saveSafetySettings() async {
    _isLoading = true;
    notifyListeners();
    try {
      await Future<void>.delayed(const Duration(milliseconds: 400));
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> saveNotificationSettings() async {
    _isLoading = true;
    notifyListeners();
    try {
      await _api.updatePreferences();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addContact(String name, String phone) async {
    final normalizedPhone = phone.trim();
    final normalizedName = name.trim();
    if (normalizedName.isEmpty || normalizedPhone.isEmpty) return false;

    final exists = _contacts.any((c) => c.phone == normalizedPhone);
    if (exists) {
      _error = 'This contact is already added.';
      notifyListeners();
      return false;
    }

    final contact = EmergencyContactModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: normalizedName,
      phone: normalizedPhone,
    );

    try {
      await _api.addEmergencyContact(
        name: normalizedName,
        phone: normalizedPhone,
      );
    } catch (e) {
      debugPrint('API addEmergencyContact failed, saving locally: $e');
    }

    _contacts = [..._contacts, contact];
    await LocalEmergencyContactsStorage.write(_contacts);
    _error = null;
    notifyListeners();
    return true;
  }

  Future<bool> removeContact(String id) async {
    try {
      await _api.removeEmergencyContact(id);
    } catch (e) {
      debugPrint('API removeEmergencyContact failed, removing locally: $e');
    }

    _contacts = _contacts.where((c) => c.id != id).toList();
    await LocalEmergencyContactsStorage.write(_contacts);
    notifyListeners();
    return true;
  }

  Future<bool> changePassword({
    required String oldPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _api.changePassword(
        oldPassword: oldPassword,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
