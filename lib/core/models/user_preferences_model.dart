class UserPreferencesModel {
  final String id;
  final String userId;
  final String? runPreference;
  final String? visitReason;
  final bool shareLiveLocation;
  final bool emergencyAlertsEnabled;
  final bool profilePublic;
  final bool shareRunHistory;
  final bool pushNotificationsEnabled;
  final bool emailNotificationsEnabled;
  final bool runRemindersEnabled;
  final bool safetyAlertsEnabled;
  final bool routeUpdatesEnabled;
  final bool communityUpdatesEnabled;
  final bool activitySettingsEnabled;

  const UserPreferencesModel({
    required this.id,
    required this.userId,
    this.runPreference,
    this.visitReason,
    this.shareLiveLocation = false,
    this.emergencyAlertsEnabled = true,
    this.profilePublic = false,
    this.shareRunHistory = false,
    this.pushNotificationsEnabled = true,
    this.emailNotificationsEnabled = true,
    this.runRemindersEnabled = true,
    this.safetyAlertsEnabled = true,
    this.routeUpdatesEnabled = true,
    this.communityUpdatesEnabled = true,
    this.activitySettingsEnabled = true,
  });

  factory UserPreferencesModel.fromJson(Map<String, dynamic> json) {
    bool readBool(dynamic value) {
      if (value == null) return false;
      if (value is bool) return value;
      if (value is num) return value == 1;
      if (value is String) return value == '1' || value.toLowerCase() == 'true';
      return false;
    }

    return UserPreferencesModel(
      id: '${json['id'] ?? ''}',
      userId: '${json['user_id'] ?? ''}',
      runPreference: json['run_preference'] as String?,
      visitReason: json['visit_reason'] as String?,
      shareLiveLocation: readBool(json['share_live_location']),
      emergencyAlertsEnabled: readBool(json['emergency_alerts_enabled']),
      profilePublic: readBool(json['profile_public']),
      shareRunHistory: readBool(json['share_run_history']),
      pushNotificationsEnabled: readBool(json['push_notifications_enabled']),
      emailNotificationsEnabled: readBool(json['email_notifications_enabled']),
      runRemindersEnabled: readBool(json['run_reminders_enabled']),
      safetyAlertsEnabled: readBool(json['safety_alerts_enabled']),
      routeUpdatesEnabled: readBool(json['route_updates_enabled']),
      communityUpdatesEnabled: readBool(json['community_updates_enabled']),
      activitySettingsEnabled: readBool(json['activity_settings_enabled']),
    );
  }

  Map<String, dynamic> toJson() => {
    'run_preference': runPreference,
    'visit_reason': visitReason,
    'share_live_location': shareLiveLocation,
    'emergency_alerts_enabled': emergencyAlertsEnabled,
    'profile_public': profilePublic,
    'share_run_history': shareRunHistory,
    'push_notifications_enabled': pushNotificationsEnabled,
    'email_notifications_enabled': emailNotificationsEnabled,
    'run_reminders_enabled': runRemindersEnabled,
    'safety_alerts_enabled': safetyAlertsEnabled,
    'route_updates_enabled': routeUpdatesEnabled,
    'community_updates_enabled': communityUpdatesEnabled,
    'activity_settings_enabled': activitySettingsEnabled,
  };
}
