import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:saefra_run/core/constants/app_colors.dart';
import 'package:saefra_run/core/services/auth_service.dart';
import 'package:saefra_run/core/services/settings_service.dart';
import 'package:saefra_run/core/widgets/app_page_header.dart';
import 'package:saefra_run/core/widgets/settings_tile.dart';
import 'package:saefra_run/generated/assets.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SettingsService>().load();
    });
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Image.asset(
              Assets.settingsLogoutIcon,
              width: 28,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.logout, color: AppColors.primary),
            ),
            SizedBox(width: 10.w),
            const Text('Logout', style: TextStyle(color: AppColors.white)),
          ],
        ),
        content: const Text(
          'Are you sure you want to logout?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<AuthService>().logout();
      if (mounted) context.goNamed('login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();
    final auth = context.watch<AuthService>();
    final user = auth.currentUser;
    final displayName = settings.firstName.isNotEmpty
        ? '${settings.firstName} ${settings.lastName}'.trim()
        : user?.fullName ?? user?.email ?? 'User';
    final email = settings.email.isNotEmpty
        ? settings.email
        : user?.email ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            AppPageHeader(
              title: 'Settings',
              onBack: () => context.goNamed('dashboard'),
            ),
            if (settings.isLoading)
              const LinearProgressIndicator(color: AppColors.primary),
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28.r,
                    backgroundColor: AppColors.surfaceLight,
                    backgroundImage: user?.profileImage != null
                        ? NetworkImage(user!.profileImage!)
                        : null,
                    child: user?.profileImage == null
                        ? Text(
                            displayName.isNotEmpty ? displayName[0] : '?',
                            style: TextStyle(
                              color: AppColors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18.sp,
                            ),
                          )
                        : null,
                  ),
                  SizedBox(width: 14.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          email,
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                children: [
                  SettingsTile(
                    label: 'Edit Profile',
                    iconAssetPath: Assets.settingsEditProfileIcon,
                    fallbackIcon: Icons.person_outline,
                    onTap: () => context.pushNamed('editProfile'),
                  ),
                  SettingsTile(
                    label: 'Safety Settings',
                    iconAssetPath: Assets.settingsSafetyIcon,
                    fallbackIcon: Icons.shield_outlined,
                    onTap: () => context.pushNamed('safetySettings'),
                  ),
                  SettingsTile(
                    label: 'Emergency Contacts',
                    iconAssetPath: Assets.settingsEmergencyIcon,
                    fallbackIcon: Icons.contact_emergency_outlined,
                    onTap: () => context.pushNamed('emergencyContacts'),
                  ),
                  SettingsTile(
                    label: 'Change Password',
                    iconAssetPath: Assets.settingsPasswordIcon,
                    fallbackIcon: Icons.lock_outline,
                    onTap: () => context.pushNamed('changePassword'),
                  ),
                  SettingsTile(
                    label: 'Notification Settings',
                    iconAssetPath: Assets.settingsNotificationIcon,
                    fallbackIcon: Icons.notifications_none,
                    onTap: () => context.pushNamed('notificationSettings'),
                  ),
                  SettingsTile(
                    label: 'Terms and Conditions',
                    iconAssetPath: Assets.settingsTermsIcon,
                    fallbackIcon: Icons.description_outlined,
                    onTap: () => context.pushNamed(
                      'legalContent',
                      queryParameters: {'type': 'terms'},
                    ),
                  ),
                  SettingsTile(
                    label: 'Privacy Policy',
                    iconAssetPath: Assets.settingsPrivacyIcon,
                    fallbackIcon: Icons.privacy_tip_outlined,
                    onTap: () => context.pushNamed(
                      'legalContent',
                      queryParameters: {'type': 'privacy'},
                    ),
                  ),
                  SettingsTile(
                    label: 'Logout',
                    iconAssetPath: Assets.settingsLogoutIcon,
                    fallbackIcon: Icons.logout,
                    onTap: _confirmLogout,
                    showChevron: false,
                  ),
                  SettingsTile(
                    label: 'About Us',
                    iconAssetPath: Assets.settingsAboutIcon,
                    fallbackIcon: Icons.info_outline,
                    onTap: () => context.pushNamed('aboutUs'),
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
