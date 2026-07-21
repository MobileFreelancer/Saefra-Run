import 'package:flutter/foundation.dart';
import 'package:saefra_run/core/config/api_config.dart';
import 'package:saefra_run/core/models/emergency_contact_model.dart';
import 'package:saefra_run/core/models/user_model.dart';
import 'package:saefra_run/core/models/user_preferences_model.dart';
import 'package:saefra_run/core/services/api_service.dart';
import 'package:saefra_run/core/services/auth_service.dart';
import 'package:saefra_run/core/services/local_emergency_contacts_storage.dart';
import 'package:saefra_run/core/services/secure_storage_service.dart';

class SettingsService extends ChangeNotifier {
  SettingsService(this._auth);

  final AuthService _auth;
  final ApiService _api = ApiService();

  UserPreferencesModel? _preferences;
  List<EmergencyContactModel> _contacts = [];
  bool _isLoading = false;
  bool _hasLoaded = false;
  String? _error;

  bool _liveTracking = true;
  bool _emergencyAlerts = true;
  bool _safetyZoneAlerts = true;
  bool _routeSafetyAlerts = false;
  bool _pushNotifications = true;
  bool _emailNotifications = false;
  bool _smsNotifications = false;

  String _firstName = '';
  String _lastName = '';
  String _email = '';
  String _phone = '';
  String _gender = 'Male';
  String _birthdate = '';
  String _runningLevel = 'Intermediate';

  UserPreferencesModel? get preferences => _preferences;
  List<EmergencyContactModel> get contacts => _contacts;
  bool get isLoading => _isLoading;
  String? get error => _error;

  bool get liveTracking => _liveTracking;
  bool get emergencyAlerts => _emergencyAlerts;
  bool get safetyZoneAlerts => _safetyZoneAlerts;
  bool get routeSafetyAlerts => _routeSafetyAlerts;
  bool get pushNotifications => _pushNotifications;
  bool get emailNotifications => _emailNotifications;
  bool get smsNotifications => _smsNotifications;

  String get firstName => _firstName;
  String get lastName => _lastName;
  String get email => _email;
  String get phone => _phone;
  String get gender => _gender;
  String get birthdate => _birthdate;
  String get runningLevel => _runningLevel;

  Future<void> load({bool refresh = false}) async {
    if (!refresh && _hasLoaded) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      UserModel user;
      final cached = _auth.currentUser;
      if (refresh ||
          cached == null ||
          (cached.firstName?.trim().isEmpty ?? true)) {
        user = await _api.getCurrentUser();
        await _auth.syncCurrentUser(user);
      } else {
        user = cached;
      }
      _hydrateProfile(user);
      _preferences = await _api.getPreferences();
      _liveTracking = _preferences?.shareLiveLocation ?? _liveTracking;
      _emergencyAlerts =
          _preferences?.emergencyAlertsEnabled ?? _emergencyAlerts;
      _pushNotifications =
          _preferences?.pushNotificationsEnabled ?? _pushNotifications;
      _emailNotifications =
          _preferences?.emailNotificationsEnabled ?? _emailNotifications;

      await _loadEmergencyContacts();
      await _loadLocalSafetySettings();
    } catch (e) {
      _error = e.toString();
      _contacts = await LocalEmergencyContactsStorage.read();
      await _loadLocalSafetySettings();
    } finally {
      _hasLoaded = true;
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadEmergencyContacts() async {
    _contacts = await _api.getEmergencyContacts();
    await LocalEmergencyContactsStorage.write(_contacts);
  }

  void _hydrateProfile(UserModel user) {
    _email = user.email ?? '';
    _phone = user.phoneNumber ?? '';
    _firstName = user.firstName?.trim() ?? '';
    _lastName = user.lastName?.trim() ?? '';
    if (_firstName.isEmpty && _lastName.isEmpty) {
      final name = user.email?.split('@').first ?? '';
      if (name.isNotEmpty) _firstName = name;
    }
    _gender = _formatGender(user.gender);

    if (user.birthdate != null) {
      final d = user.birthdate!;
      _birthdate =
          '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year}';
    }
    _runningLevel = _formatRunningLevel(user.runPreference);
  }

  String _formatGender(String? value) {
    if (value == null || value.isEmpty) return 'Male';
    final lower = value.toLowerCase();
    if (lower == 'female') return 'Female';
    if (lower.contains('not')) return 'Prefer not to say';
    return 'Male';
  }

  String _formatRunningLevel(String? value) {
    if (value == null || value.isEmpty) return 'Intermediate';
    final lower = value.toLowerCase();
    if (lower.contains('easy') || lower.contains('beginner')) {
      return 'Beginner';
    }
    if (lower.contains('hard') || lower.contains('advanced')) {
      return 'Advanced';
    }
    return 'Intermediate';
  }

  void updateProfileFields({
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? gender,
    String? birthdate,
    String? runningLevel,
  }) {
    if (firstName != null) _firstName = firstName;
    if (lastName != null) _lastName = lastName;
    if (email != null) _email = email;
    if (phone != null) _phone = phone;
    if (gender != null) _gender = gender;
    if (birthdate != null) _birthdate = birthdate;
    if (runningLevel != null) _runningLevel = runningLevel;
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

  void setSafetyZoneAlerts(bool v) {
    _safetyZoneAlerts = v;
    notifyListeners();
  }

  void setRouteSafetyAlerts(bool v) {
    _routeSafetyAlerts = v;
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
        gender: _gender.toLowerCase().contains('female')
            ? 'female'
            : _gender.toLowerCase().contains('not')
                ? 'prefer_not_to_say'
                : 'male',
        birthdate: _birthdate.isNotEmpty ? _birthdate : '01-01-1990',
        firstName: _firstName,
        lastName: _lastName,
        mobileNumber: _phone,
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
    _error = null;
    notifyListeners();
    try {
      await _persistLocalSafetySettings();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadLocalSafetySettings() async {
    try {
      final raw = await SecureStorageService.instance.read(
        key: ApiConfig.storageKeySafetySettings,
      );
      if (raw == null || raw.isEmpty) return;

      final decoded = raw.split('|');
      if (decoded.length >= 2) {
        _safetyZoneAlerts = decoded[0] == '1';
        _routeSafetyAlerts = decoded[1] == '1';
      }
    } catch (e) {
      debugPrint('Failed to load local safety settings: $e');
    }
  }

  Future<void> _persistLocalSafetySettings() async {
    final payload = [
      _safetyZoneAlerts ? '1' : '0',
      _routeSafetyAlerts ? '1' : '0',
    ].join('|');

    await SecureStorageService.instance.write(
      key: ApiConfig.storageKeySafetySettings,
      value: payload,
    );
    await Future<void>.delayed(const Duration(milliseconds: 300));
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

  Future<bool> addContact(
    String name,
    String phone, {
    String? imagePath,
  }) async {
    final normalizedPhone = phone.trim();
    final normalizedName = name.trim();
    if (normalizedName.isEmpty || normalizedPhone.isEmpty) return false;

    final exists = _contacts.any((c) => c.phone == normalizedPhone);
    if (exists) {
      _error = 'This contact is already added.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _api.addEmergencyContact(
        name: normalizedName,
        phone: normalizedPhone,
        imagePath: imagePath,
      );
      await _loadEmergencyContacts();
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> removeContact(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _api.removeEmergencyContact(id);
      await _loadEmergencyContacts();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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
      await SecureStorageService.instance.write(
        key: ApiConfig.storageKeyUserPassword,
        value: newPassword,
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
