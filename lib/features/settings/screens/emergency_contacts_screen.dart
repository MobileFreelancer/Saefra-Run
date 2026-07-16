import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:saefra_run/core/constants/app_colors.dart';
import 'package:saefra_run/core/services/contact_service.dart';
import 'package:saefra_run/core/services/settings_service.dart';
import 'package:saefra_run/core/widgets/app_page_header.dart';
import 'package:saefra_run/core/widgets/emergency_contact_avatar.dart';
import 'package:saefra_run/core/widgets/primary_button.dart';
import 'package:saefra_run/core/widgets/secondary_button.dart';
import 'package:saefra_run/generated/assets.dart';

class EmergencyContactsScreen extends StatefulWidget {
  const EmergencyContactsScreen({super.key});

  @override
  State<EmergencyContactsScreen> createState() =>
      _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends State<EmergencyContactsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SettingsService>().load();
    });
  }

  Future<void> _importFromContacts() async {
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
      if (!mounted || picked == null) return;
    }

    final settings = context.read<SettingsService>();
    final ok = await settings.addContact(picked.name, picked.phone);
    if (!mounted) return;

    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(settings.error ?? 'Failed to add contact')),
      );
    }
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
            const Text('Remove Contact', style: TextStyle(color: AppColors.white)),
          ],
        ),
        content: Text(
          'Remove $name from emergency contacts?',
          style: const TextStyle(color: AppColors.textSecondary),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(settings.error ?? 'Failed to remove contact')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const AppPageHeader(title: 'Emergency Contacts'),
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 8.h),
              child: SecondaryButton(
                label: 'Add Contact Manually',
                onPressed: () => context.pushNamed('addEmergencyContact'),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 12.h),
              child: PrimaryButton(
                label: context.watch<ContactService>().isLoading
                    ? 'Opening Contacts...'
                    : 'Import from Contacts',
                onPressed: context.watch<ContactService>().isLoading
                    ? null
                    : _importFromContacts,
              ),
            ),
            Expanded(
              child: settings.isLoading && settings.contacts.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    )
                  : settings.contacts.isEmpty
                      ? Center(
                          child: Padding(
                            padding: EdgeInsets.all(24.w),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(
                                  Assets.settingsEmergencyIcon,
                                  width: 64.w,
                                  errorBuilder: (_, __, ___) => Icon(
                                    Icons.contact_phone_outlined,
                                    size: 64.sp,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                                SizedBox(height: 16.h),
                                Text(
                                  'No emergency contacts yet',
                                  style: TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 14.sp,
                                  ),
                                ),
                                SizedBox(height: 8.h),
                                Text(
                                  'Pick contacts from your phone to add them here.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 12.sp,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: EdgeInsets.all(16.w),
                          itemCount: settings.contacts.length,
                          separatorBuilder: (_, __) => SizedBox(height: 10.h),
                          itemBuilder: (context, index) {
                            final contact = settings.contacts[index];
                            return Container(
                              padding: EdgeInsets.all(14.w),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(14.r),
                              ),
                              child: Row(
                                children: [
                                  EmergencyContactAvatar(
                                    contact: contact,
                                    radius: 22,
                                  ),
                                  SizedBox(width: 12.w),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          contact.name,
                                          style: TextStyle(
                                            color: AppColors.white,
                                            fontSize: 14.sp,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        SizedBox(height: 4.h),
                                        Text(
                                          contact.phone,
                                          style: TextStyle(
                                            color: AppColors.textMuted,
                                            fontSize: 12.sp,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () =>
                                        _removeContact(contact.id, contact.name),
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
