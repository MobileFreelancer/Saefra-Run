import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:saefra_run/core/constants/app_colors.dart';
import 'package:saefra_run/core/models/emergency_contact_model.dart';
import 'package:saefra_run/core/services/contact_service.dart';
import 'package:saefra_run/core/services/safety_checkin_service.dart';
import 'package:saefra_run/core/services/settings_service.dart';
import 'package:saefra_run/core/widgets/app_page_header.dart';
import 'package:saefra_run/core/widgets/primary_button.dart';

class SafetyCheckInScreen extends StatefulWidget {
  const SafetyCheckInScreen({
    super.key,
    this.routeId,
    this.routeName,
  });

  final String? routeId;
  final String? routeName;

  @override
  State<SafetyCheckInScreen> createState() => _SafetyCheckInScreenState();
}

class _SafetyCheckInScreenState extends State<SafetyCheckInScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final settings = context.read<SettingsService>();
      if (settings.contacts.isEmpty) {
        await settings.load();
      }
      if (!mounted) return;
      context.read<SafetyCheckInService>().seedContacts(settings.contacts);
    });
  }

  Future<void> _addEmergencyContact() async {
    final contactService = context.read<ContactService>();
    final picked = await contactService.pickFromDevice();

    if (!mounted) return;
    if (picked == null) {
      final message = contactService.statusMessage;
      if (message != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
      return;
    }

    final settings = context.read<SettingsService>();
    final ok = await settings.addContact(picked.name, picked.phone);
    if (!mounted || !ok) return;

    final added = settings.contacts.lastWhere(
      (c) => c.phone == picked.phone,
      orElse: () => EmergencyContactModel(
        id: '${settings.contacts.length}',
        name: picked.name,
        phone: picked.phone,
      ),
    );
    context.read<SafetyCheckInService>().addContactSelection(added);
  }

  void _startRun() {
    context.pushNamed(
      'liveRunning',
      queryParameters: {
        if (widget.routeId != null) 'routeId': widget.routeId!,
        if (widget.routeName != null) 'routeName': widget.routeName!,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final checkIn = context.watch<SafetyCheckInService>();
    final settings = context.watch<SettingsService>();
    final textTheme = Theme.of(context).textTheme;
    final contacts = settings.contacts;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const AppPageHeader(title: 'Safety Check-In'),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 24.h),
                children: [
                  Text(
                    "Let someone know you're heading out for your run. These settings will only be active during this run.",
                    style: textTheme.bodyMedium?.copyWith(height: 1.45),
                  ),
                  SizedBox(height: 20.h),
                  Text('Live Tracking', style: textTheme.titleMedium),
                  SizedBox(height: 10.h),
                  _ToggleCard(
                    description:
                        "Who should know you're running? Choose whether you'd like someone to be notified while you're running.",
                    value: checkIn.liveTrackingEnabled,
                    onChanged: checkIn.setLiveTracking,
                    child: checkIn.liveTrackingEnabled
                        ? Column(
                            children: contacts
                                .map(
                                  (c) => _ContactCheckRow(
                                    contact: c,
                                    selected:
                                        checkIn.isTrackingContactSelected(c.id),
                                    onChanged: () =>
                                        checkIn.toggleTrackingContact(c.id),
                                  ),
                                )
                                .toList(),
                          )
                        : null,
                  ),
                  SizedBox(height: 20.h),
                  Text('Live Location sharing', style: textTheme.titleMedium),
                  SizedBox(height: 10.h),
                  _ToggleCard(
                    description:
                        'Share your live location only during this run.',
                    value: checkIn.liveLocationSharingEnabled,
                    onChanged: checkIn.setLiveLocationSharing,
                    child: checkIn.liveLocationSharingEnabled
                        ? Column(
                            children: [
                              ...contacts.map(
                                (c) => _ContactCheckRow(
                                  contact: c,
                                  selected:
                                      checkIn.isSharingContactSelected(c.id),
                                  onChanged: () =>
                                      checkIn.toggleSharingContact(c.id),
                                ),
                              ),
                              SizedBox(height: 10.h),
                              _AddContactButton(onTap: _addEmergencyContact),
                            ],
                          )
                        : _AddContactButton(onTap: _addEmergencyContact),
                  ),
                  SizedBox(height: 20.h),
                  Text('Expected Run Time', style: textTheme.titleMedium),
                  SizedBox(height: 8.h),
                  Text(
                    'If your run exceeds this time plus a short grace period, your emergency contact will be notified.',
                    style: textTheme.bodySmall?.copyWith(height: 1.4),
                  ),
                  SizedBox(height: 12.h),
                  _RunTimeGrid(
                    selected: checkIn.expectedRunMinutes,
                    onSelect: checkIn.setExpectedRunMinutes,
                  ),
                  SizedBox(height: 20.h),
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.shield_outlined,
                              color: AppColors.primary,
                              size: 20.sp,
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              'How Safety Check-In Works',
                              style: textTheme.titleMedium?.copyWith(
                                fontSize: 14.sp,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12.h),
                        ...[
                          'Contacts notified only if chosen',
                          'Live location shared only while running',
                          'Sharing ends automatically',
                          'Timeout alert with last known location',
                        ].map(
                          (line) => Padding(
                            padding: EdgeInsets.only(bottom: 8.h),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.check,
                                  color: AppColors.primary,
                                  size: 16.sp,
                                ),
                                SizedBox(width: 8.w),
                                Expanded(
                                  child: Text(line, style: textTheme.bodySmall),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 8.h),
              child: PrimaryButton(label: 'Start Run', onPressed: _startRun),
            ),
            TextButton(
              onPressed: () => context.goNamed('dashboard'),
              child: Text(
                'Skip for Today',
                style: textTheme.bodyLarge,
              ),
            ),
            SizedBox(height: 8.h),
          ],
        ),
      ),
    );
  }
}

class _ToggleCard extends StatelessWidget {
  const _ToggleCard({
    required this.description,
    required this.value,
    required this.onChanged,
    this.child,
  });

  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  description,
                  style: textTheme.bodySmall?.copyWith(height: 1.4),
                ),
              ),
              Switch(
                value: value,
                onChanged: onChanged,
                activeThumbColor: AppColors.white,
                activeTrackColor: AppColors.primary,
              ),
            ],
          ),
          if (child != null) ...[
            SizedBox(height: 10.h),
            child!,
          ],
        ],
      ),
    );
  }
}

class _ContactCheckRow extends StatelessWidget {
  const _ContactCheckRow({
    required this.contact,
    required this.selected,
    required this.onChanged,
  });

  final EmergencyContactModel contact;
  final bool selected;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18.r,
            backgroundColor: AppColors.surfaceLight,
            child: Text(
              contact.name[0],
              style: textTheme.labelLarge,
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contact.name,
                  style: textTheme.titleMedium?.copyWith(fontSize: 14.sp),
                ),
                Text(
                  contact.phone,
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
          ),
          Checkbox(
            value: selected,
            onChanged: (_) => onChanged(),
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

class _AddContactButton extends StatelessWidget {
  const _AddContactButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 14.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: AppColors.primary,
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, color: AppColors.primary, size: 18.sp),
            SizedBox(width: 6.w),
            Text(
              'Add Emergency Contact',
              style: textTheme.labelLarge?.copyWith(color: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }
}

class _RunTimeGrid extends StatelessWidget {
  const _RunTimeGrid({required this.selected, required this.onSelect});

  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final options = [30, 45, 60];
    final textTheme = Theme.of(context).textTheme;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10.h,
      crossAxisSpacing: 10.w,
      childAspectRatio: 2.8,
      children: [
        ...options.map(
          (min) {
            final isSelected = selected == min;
            return GestureDetector(
              onTap: () => onSelect(min),
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.2)
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.border,
                  ),
                ),
                child: Text(
                  '$min min',
                  style: textTheme.titleMedium?.copyWith(
                    color: isSelected ? AppColors.primary : AppColors.white,
                  ),
                ),
              ),
            );
          },
        ),
        GestureDetector(
          onTap: () {},
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: AppColors.border),
            ),
            child: Text('Custom', style: textTheme.titleMedium),
          ),
        ),
      ],
    );
  }
}
