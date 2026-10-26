import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:saefra_run/core/constants/app_colors.dart';
import 'package:saefra_run/core/services/settings_service.dart';
import 'package:saefra_run/core/widgets/app_page_header.dart';
import 'package:saefra_run/core/widgets/primary_button.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SettingsService>().load(refresh: true);
    });
  }

  Future<void> _updateSetting(Future<void> Function(bool) setter, bool value) async {
    await setter(value);
    final settings = context.read<SettingsService>();
    await settings.saveNotificationSettings();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const AppPageHeader(title: 'Notifications'),
            if (settings.isLoading)
              const LinearProgressIndicator(
                minHeight: 2,
                color: AppColors.primary,
                backgroundColor: Colors.transparent,
              ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                children: [
                  // Allow Push Notifications - Master Toggle
                  Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.surfaced1B,
                      borderRadius: BorderRadius.circular(16.r),
                      boxShadow: [ BoxShadow( color: AppColors.orangeShadow.withValues(alpha: 0.15), blurRadius: 20 ) ],
                      border: Border.all(color: AppColors.border),
                    ),
                    child: _NotificationToggleRow(
                      title: 'Allow Push Notifications',
                      value: settings.pushNotifications,
                      onChanged: (v) => _updateSetting((val) async => settings.setPushNotifications(val), v),
                    ),
                  ),
                  SizedBox(height: 24.h),

                  // Notify Me About Section
                  Text(
                    'Notify Me About',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.white,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaced1B,
                      borderRadius: BorderRadius.circular(16.r),
                      boxShadow: [ BoxShadow( color: AppColors.orangeShadow.withValues(alpha: 0.15), blurRadius: 20 ) ],
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        _NotificationToggleRow(
                          title: 'Run Reminders',
                          value: settings.runReminders,
                          onChanged: (v) => _updateSetting((val) async => settings.setRunReminders(val), v),
                        ),

                        Divider(
                          height: 0.5,
                          thickness: 1.2,
                          color: AppColors.border,
                          indent: 16.w,
                          endIndent: 16.w,
                        ),
                        _NotificationToggleRow(
                          title: 'Safety Alerts',
                          value: settings.safetyAlerts,
                          onChanged: (v) => _updateSetting((val) async => settings.setSafetyAlerts(val), v),
                        ),

                        Divider(
                          height: 0.5,
                          thickness: 1.2,
                          color: AppColors.border,
                          indent: 16.w,
                          endIndent: 16.w,
                        ),
                        _NotificationToggleRow(
                          title: 'Route Updates',
                          value: settings.routeUpdates,
                          onChanged: (v) => _updateSetting((val) async => settings.setRouteUpdates(val), v),
                        ),

                        Divider(
                          height: 0.5,
                          thickness: 1.2,
                          color: AppColors.border,
                          indent: 16.w,
                          endIndent: 16.w,
                        ),
                        _NotificationToggleRow(
                          title: 'Community Updates',
                          value: settings.communityUpdates,
                          onChanged: (v) => _updateSetting((val) async => settings.setCommunityUpdates(val), v),
                        ),

                        Divider(
                          height: 0.5,
                          thickness: 1.2,
                          color: AppColors.border,
                          indent: 16.w,
                          endIndent: 16.w,
                        ),
                        _NotificationToggleRow(
                          title: 'Activity Settings',
                          value: settings.activitySettings,
                          onChanged: (v) => _updateSetting((val) async => settings.setActivitySettings(val), v),
                        ),

                      ],
                    ),
                  ),
                  SizedBox(height: 32.h),

                  // Info Text
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.w),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16.sp,
                          color: AppColors.textMuted,
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            'You can manage notification preferences at any time.',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textMuted,
                              fontSize: 12.sp,
                              height: 1.4,
                              fontWeight: FontWeight.w500
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationToggleRow extends StatelessWidget {
  const _NotificationToggleRow({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:   EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.white,
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Transform.scale(
            scale: 0.8,
            child: Switch(
              value: value,
              padding: EdgeInsets.zero,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              onChanged: onChanged,
              activeThumbColor: AppColors.white,
              activeTrackColor: AppColors.primary,
              inactiveThumbColor: Colors.grey[600],
              inactiveTrackColor: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }
}
