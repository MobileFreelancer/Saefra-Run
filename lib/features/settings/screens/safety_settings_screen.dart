import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:saefra_run/core/constants/app_colors.dart';
import 'package:saefra_run/core/models/emergency_contact_model.dart';
import 'package:saefra_run/core/services/contact_service.dart';
import 'package:saefra_run/core/services/settings_service.dart';
import 'package:saefra_run/core/widgets/app_page_header.dart';
import 'package:saefra_run/core/widgets/emergency_contact_avatar.dart';
import 'package:saefra_run/core/widgets/primary_button.dart';
import 'package:saefra_run/generated/assets.dart';

class SafetySettingsScreen extends StatefulWidget {
  const SafetySettingsScreen({super.key});

  @override
  State<SafetySettingsScreen> createState() => _SafetySettingsScreenState();
}

class _SafetySettingsScreenState extends State<SafetySettingsScreen> {
  String? _saveError;
  String? _contactError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SettingsService>().load();
    });
  }

  Future<void> _save() async {
    setState(() => _saveError = null);

    final settings = context.read<SettingsService>();
    final ok = await settings.saveSafetySettings();
    if (!mounted) return;

    if (!ok) {
      setState(() => _saveError = settings.error ?? 'Save failed');
      return;
    }

    context.pop();
  }

  Future<void> _removeContact(String id, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Row(
          children: [
            Image.asset(
              Assets.settingsEmergencyIcon,
              width: 28,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.warning_amber, color: AppColors.primary),
            ),
            SizedBox(width: 8.w),
            Text(
              'Remove Contact',
              style: Theme.of(ctx).textTheme.titleMedium,
            ),
          ],
        ),
        content: Text(
          'Remove $name from emergency contacts?',
          style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Yes'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final settings = context.read<SettingsService>();
      final ok = await settings.removeContact(id);
      if (!mounted) return;
      if (!ok) {
        setState(() => _contactError = settings.error ?? 'Failed to remove contact');
      }
    }
  }

  Future<void> _importFromContacts() async {
    setState(() => _contactError = null);

    final contactService = context.read<ContactService>();
    var picked = await contactService.pickFromDevice();

    if (!mounted) return;

    if (picked == null) {
      final message = contactService.statusMessage;
      if (message == null) return;

      final retry = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
          title: Text(
            'Contacts Permission',
            style: Theme.of(ctx).textTheme.titleMedium,
          ),
          content: Text(
            '$message\n\nWould you like to allow access now?',
            style: Theme.of(ctx).textTheme.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Not Now'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Try Again'),
            ),
          ],
        ),
      );

      if (retry != true || !mounted) return;

      picked = await contactService.pickFromDevice(allowSecondPrompt: true);
      if (!mounted) return;

      if (picked == null) {
        final status = contactService.statusMessage;
        if (status != null) {
          setState(() => _contactError = status);
        }
        return;
      }
    }

    final settings = context.read<SettingsService>();
    final ok = await settings.addContact(picked.name, picked.phone);
    if (!mounted) return;

    if (!ok) {
      setState(() => _contactError = settings.error ?? 'Failed to add contact');
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();
    final contactService = context.watch<ContactService>();
    final textTheme = Theme.of(context).textTheme;
    final contactCount = settings.contacts.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const AppPageHeader(title: 'Safety Settings'),
            // if (settings.isLoading && settings.contacts.isEmpty)
            //   const LinearProgressIndicator(color: AppColors.primary),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h),
                children: [
                  _SectionTitle(
                    title: 'Emergency Contacts Notified',
                    textTheme: textTheme,
                  ),
                  SizedBox(height: 10.h),
                  _EmergencyContactsSection(
                    contacts: settings.contacts,
                    textTheme: textTheme,
                    onRemove: _removeContact,
                    onAdd: contactService.isLoading ? null : _importFromContacts,
                    isImporting: contactService.isLoading,
                    contactError: _contactError,
                  ),
                  SizedBox(height: 22.h),
                  _SectionTitle(
                    title: 'Live Tracking',
                    textTheme: textTheme,
                  ),
                  SizedBox(height: 10.h),
                  _SettingsCard(
                    children: [
                      _ToggleSettingRow(
                        title: 'Share Live Location',
                        subtitle:
                            'Share your live location only while you\'re running.',
                        value: settings.liveTracking,
                        onChanged: settings.setLiveTracking,
                        textTheme: textTheme,
                      ),
                      Divider(
                        height: 1,
                        color: AppColors.border.withValues(alpha: 0.6),
                      ),
                      _NavigationSettingRow(
                        title: 'Share With Location',
                        subtitle: 'Choose specific contacts',
                        trailing: '$contactCount Contacts >',
                        textTheme: textTheme,
                        onTap: () => context.pushNamed('emergencyContacts'),
                      ),
                    ],
                  ),
                  SizedBox(height: 22.h),
                  _SectionTitle(
                    title: 'Safety Alerts',
                    textTheme: textTheme,
                  ),
                  SizedBox(height: 10.h),
                  _SettingsCard(
                    children: [
                      _ToggleSettingRow(
                        title: 'Safety Zone Alerts',
                        subtitle:
                            'Vibrate when entering low-visibility areas.',
                        value: settings.safetyZoneAlerts,
                        onChanged: settings.setSafetyZoneAlerts,
                        textTheme: textTheme,
                      ),
                      Divider(
                        height: 1,
                        color: AppColors.border.withValues(alpha: 0.6),
                      ),
                      _ToggleSettingRow(
                        title: 'Route Safety Alerts',
                        subtitle:
                            'Real-time hazards based on community data.',
                        value: settings.routeSafetyAlerts,
                        onChanged: settings.setRouteSafetyAlerts,
                        textTheme: textTheme,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
              child: Column(
                children: [
                  if (_saveError != null) ...[
                    Text(
                      _saveError!,
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.error,
                        fontSize: 12.sp,
                      ),
                    ),
                    SizedBox(height: 10.h),
                  ],
                  SizedBox(
                    width: double.infinity,
                    child: PrimaryButton(
                      label: 'Save Changes',
                      isLoading: settings.isLoading,
                      onPressed: _save,
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.textTheme,
  });

  final String title;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: textTheme.titleMedium?.copyWith(
        fontSize: 15.sp,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _EmergencyContactsSection extends StatelessWidget {
  const _EmergencyContactsSection({
    required this.contacts,
    required this.textTheme,
    required this.onRemove,
    required this.onAdd,
    this.isImporting = false,
    this.contactError,
  });

  final List<EmergencyContactModel> contacts;
  final TextTheme textTheme;
  final Future<void> Function(String id, String name) onRemove;
  final VoidCallback? onAdd;
  final bool isImporting;
  final String? contactError;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColors.surfaced1B,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: AppColors.primaryDark.withValues(alpha: 0.55),
        ),
      ),
      child: Column(
        children: [
          if (contacts.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 12.h),
              child: Text(
                'No emergency contacts added yet',
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.textMuted,
                  fontSize: 12.sp,
                ),
              ),
            )
          else
            ...contacts.map(
              (contact) => Padding(
                padding: EdgeInsets.only(bottom: 10.h),
                child: _EmergencyContactTile(
                  contact: contact,
                  textTheme: textTheme,
                  onRemove: () => onRemove(contact.id, contact.name),
                ),
              ),
            ),
          _DashedAddButton(
            label: isImporting ? 'Opening Contacts...' : 'Add Emergency Contact',
            onTap: onAdd,
            textTheme: textTheme,
            isLoading: isImporting,
          ),
          if (contactError != null) ...[
            SizedBox(height: 8.h),
            Text(
              contactError!,
              textAlign: TextAlign.center,
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.error,
                fontSize: 12.sp,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmergencyContactTile extends StatelessWidget {
  const _EmergencyContactTile({
    required this.contact,
    required this.textTheme,
    required this.onRemove,
  });

  final EmergencyContactModel contact;
  final TextTheme textTheme;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Row(
        children: [
          EmergencyContactAvatar(
            contact: contact,
            radius: 22,
            fontSize: 16.sp,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contact.name,
                  style: textTheme.titleSmall?.copyWith(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  contact.phone,
                  style: textTheme.bodySmall?.copyWith(
                    fontSize: 12.sp,
                    color: AppColors.success,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 34.w,
              height: 34.w,
              decoration: BoxDecoration(
                color: AppColors.surfaced1B,
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.35),
                ),
              ),
              child: Icon(
                Icons.delete_outline,
                color: AppColors.primary,
                size: 18.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashedAddButton extends StatelessWidget {
  const _DashedAddButton({
    required this.label,
    required this.onTap,
    required this.textTheme,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onTap;
  final TextTheme textTheme;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(
        color: AppColors.primary,
        radius: 14.r,
        dashWidth: 6,
        dashGap: 4,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onTap,
          borderRadius: BorderRadius.circular(14.r),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 14.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLoading)
                  SizedBox(
                    width: 18.w,
                    height: 18.w,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.textPrimary,
                    ),
                  )
                else
                  Icon(Icons.add, color: AppColors.textPrimary, size: 18.sp),
                SizedBox(width: 6.w),
                Text(
                  label,
                  style: textTheme.labelLarge?.copyWith(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({
    required this.color,
    required this.radius,
    required this.dashWidth,
    required this.dashGap,
  });

  final Color color;
  final double radius;
  final double dashWidth;
  final double dashGap;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final rect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );

    final path = Path()..addRRect(rect);
    final metrics = path.computeMetrics();

    for (final metric in metrics) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = math.min(distance + dashWidth, metric.length);
        final extract = metric.extractPath(distance, next);
        canvas.drawPath(extract, paint);
        distance += dashWidth + dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.radius != radius;
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaced1B,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(children: children),
    );
  }
}

class _ToggleSettingRow extends StatelessWidget {
  const _ToggleSettingRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.textTheme,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.titleSmall?.copyWith(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  subtitle,
                  style: textTheme.bodySmall?.copyWith(
                    fontSize: 12.sp,
                    color: AppColors.textMuted,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          Switch(
            value: value,
            onChanged: onChanged,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            activeThumbColor: AppColors.white,
            activeTrackColor: AppColors.buttonColor,
            inactiveThumbColor: AppColors.white,
            inactiveTrackColor: AppColors.border,
          ),
        ],
      ),
    );
  }
}

class _NavigationSettingRow extends StatelessWidget {
  const _NavigationSettingRow({
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.textTheme,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String trailing;
  final TextTheme textTheme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.r),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: textTheme.titleSmall?.copyWith(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    subtitle,
                    style: textTheme.bodySmall?.copyWith(
                      fontSize: 12.sp,
                      color: AppColors.textMuted,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 8.w),
            Text(
              trailing,
              style: textTheme.labelLarge?.copyWith(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.buttonColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
