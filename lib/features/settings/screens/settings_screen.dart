import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:saefra_run/core/constants/app_colors.dart';
import 'package:saefra_run/core/services/auth_service.dart';
import 'package:saefra_run/core/services/onboarding_service.dart';
import 'package:saefra_run/core/services/settings_service.dart';
import 'package:saefra_run/core/utils/navigation_utils.dart';
import 'package:saefra_run/core/widgets/app_bottom_nav.dart';
import 'package:saefra_run/core/widgets/settings_tile.dart';
import 'package:saefra_run/features/settings/widgets/logout_dialog.dart';
import 'package:saefra_run/core/widgets/app_cached_image.dart';

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
    var isLoading = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: !isLoading,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return LogoutDialog(
            isLoading: isLoading,
            onCancel: isLoading ? () {} : () => Navigator.pop(ctx),
            onConfirm: () async {
              setDialogState(() => isLoading = true);
              await context.read<AuthService>().logout();
              await context.read<OnboardingService>().resetOnLogout();
              if (!ctx.mounted) return;
             // Navigator.pop(ctx);
              if (mounted) context.goNamed('login');
            },
          );
        },
      ),
    );
  }

  Future<void> _confirmDeleteAccount() async {
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.background,
        title: const Text('Delete Account', style: TextStyle(color: Colors.white)),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Are you sure you want to delete your account? This action is permanent and cannot be undone.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: passwordController,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Enter your password',
                  hintStyle: TextStyle(color: AppColors.textMuted),
                ),
                validator: (v) => (v == null || v.isEmpty) ? 'Password required' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final auth = context.read<AuthService>();
              final success = await auth.deleteAccount(password: passwordController.text);
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              if (success) {
                if (mounted) context.goNamed('login');
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(auth.error ?? 'Delete failed')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();
    final auth = context.watch<AuthService>();
    final user = auth.currentUser;
    final textTheme = Theme.of(context).textTheme;
    final displayName = settings.firstName.isNotEmpty
        ? '${settings.firstName} ${settings.lastName}'.trim()
        : user?.firstName ?? user?.email ?? 'User';
    final email = settings.email.isNotEmpty
        ? settings.email
        : user?.email ?? '';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) handleRootBack(context);
      },
      child: Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 8.h),
              child: Center(
                child: Text(
                  'Settings',
                  style: textTheme.titleLarge?.copyWith(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () =>
                    context.read<SettingsService>().load(refresh: true),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h),
                children: [
                  Container(
                    padding: EdgeInsets.all(14.w),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(color: AppColors.borderColor),
                    ),
                    child: Row(
                      children: [
                        user?.profileImage != null && user!.profileImage!.isNotEmpty
                            ? AppCircleCachedImage(
                                imageUrl: user.profileImage!,
                                width: 56.r,
                                height: 56.r,
                                fit: BoxFit.cover,
                              )
                            : CircleAvatar(
                                radius: 28.r,
                                backgroundColor: AppColors.surfaceLight,
                                child: Text(
                                  displayName.isNotEmpty
                                      ? displayName[0].toUpperCase()
                                      : '?',
                                  style: textTheme.titleLarge?.copyWith(
                                    fontSize: 20.sp,
                                  ),
                                ),
                              ),
                        SizedBox(width: 14.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                displayName,
                                style: textTheme.titleMedium?.copyWith(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                email,
                                style: textTheme.bodySmall?.copyWith(
                                  fontSize: 14.sp,
                                  color: Color(0xFFE2E2E2)  ,
                                  fontWeight: FontWeight.w400
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),
                  _SettingsGroup(
                    children: [
                      SettingsTile(
                        label: 'Personal Information',
                        fallbackIcon: Icons.person_outline,
                        onTap: () => context.pushNamed('editProfile'),
                      ),
                      //_SettingsDivider(),
                      SettingsTile(
                        label: 'Safety Settings',
                        fallbackIcon: Icons.shield_outlined,
                        onTap: () => context.pushNamed('safetySettings'),
                      ),
                      _SettingsDivider(),
                       SettingsTile(
                         label: 'Notification',
                         fallbackIcon: Icons.notifications_none,
                        onTap: () => context.pushNamed('notificationSettings'),
                       ),
                     _SettingsDivider(),
                      SettingsTile(
                        dividerColors: Colors.transparent,
                        label: 'Change Password',
                        fallbackIcon: Icons.lock_outline,
                        onTap: () => context.pushNamed('changePassword'),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  _SettingsGroup(
                    children: [
                      SettingsTile(
                        label: 'Contact Us',
                        fallbackIcon: Icons.mail_outline,
                        onTap: () => context.pushNamed('contactUs'),
                      ),
                      //_SettingsDivider(),
                      SettingsTile(
                        label: 'Privacy & Policy',
                        fallbackIcon: Icons.privacy_tip_outlined,
                        onTap: () => context.pushNamed(
                          'legalContent',
                          queryParameters: {'type': 'privacy'},
                        ),
                      ),
                     // _SettingsDivider(),
                      SettingsTile(
                        label: 'Terms & Conditions',
                        fallbackIcon: Icons.description_outlined,
                        onTap: () => context.pushNamed(
                          'legalContent',
                          queryParameters: {'type': 'terms'},
                        ),
                      ),
                      //_SettingsDivider(),
                      SettingsTile(
                        dividerColors: Colors.transparent,
                        label: 'About saefra',
                        fallbackIcon: Icons.info_outline,
                        onTap: () => context.pushNamed('aboutUs'),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),

                  _SettingsGroup(
                    children: [
                      SettingsTile(
                        dividerColors: Colors.transparent,
                        label: 'Delete Account',
                        fallbackIcon: Icons.delete_outline,
                        onTap: () => _confirmDeleteAccount(),
                        isDestructive: true,
                      ),
                      _SettingsDivider(),
                      SettingsTile(
                        dividerColors: Colors.transparent,
                        label: 'Logout',
                        fallbackIcon: Icons.logout,
                        onTap: _confirmLogout,
                        isDestructive: true,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNav(activeIndex: 3),
    ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaced1B,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
              color: AppColors.orangeShadow.withValues(alpha: 0.15),
              blurRadius: 20
          )
        ],
        border: Border.all(color: AppColors.border),
      ),
      child: Column(children: children),
    );
  }
}

class _SettingsDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 0.5,
      thickness: 0.5,
      color: AppColors.border,
      indent: 16.w,
      endIndent: 16.w,
    );
  }
}
