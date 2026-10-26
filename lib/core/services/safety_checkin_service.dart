import 'package:flutter/foundation.dart';
import 'package:saefra_run/core/models/emergency_contact_model.dart';

class SafetyCheckInService extends ChangeNotifier {
  bool _liveTrackingEnabled = true;
  bool _liveLocationSharingEnabled = false;
  int _expectedRunMinutes = 45;
  final Set<String> _trackingContactIds = {};
  final Set<String> _sharingContactIds = {};

  bool get liveTrackingEnabled => _liveTrackingEnabled;
  bool get liveLocationSharingEnabled => _liveLocationSharingEnabled;
  int get expectedRunMinutes => _expectedRunMinutes;

  void setLiveTracking(bool value) {
    _liveTrackingEnabled = value;
    notifyListeners();
  }

  void setLiveLocationSharing(bool value) {
    _liveLocationSharingEnabled = value;
    notifyListeners();
  }

  void setExpectedRunMinutes(int minutes) {
    _expectedRunMinutes = minutes;
    notifyListeners();
  }

  bool isTrackingContactSelected(String id) =>
      _trackingContactIds.contains(id);

  bool isSharingContactSelected(String id) =>
      _sharingContactIds.contains(id);

  void toggleTrackingContact(String id) {
    if (_trackingContactIds.contains(id)) {
      _trackingContactIds.remove(id);
    } else {
      _trackingContactIds.add(id);
    }
    notifyListeners();
  }

  void toggleSharingContact(String id) {
    if (_sharingContactIds.contains(id)) {
      _sharingContactIds.remove(id);
    } else {
      _sharingContactIds.add(id);
    }
    notifyListeners();
  }

  void seedContacts(List<EmergencyContactModel> contacts) {
    // Contacts come from device/settings only — user selects manually.
    notifyListeners();
  }

  void addContactSelection(EmergencyContactModel contact) {
    _trackingContactIds.add(contact.id);
    _sharingContactIds.add(contact.id);
    notifyListeners();
  }
}
