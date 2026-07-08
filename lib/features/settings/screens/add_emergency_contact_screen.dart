import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:saefra_run/core/constants/app_colors.dart';
import 'package:saefra_run/core/services/contact_service.dart';
import 'package:saefra_run/core/services/settings_service.dart';
import 'package:saefra_run/core/widgets/app_page_header.dart';
import 'package:saefra_run/core/widgets/app_text_field.dart';
import 'package:saefra_run/core/widgets/primary_button.dart';
import 'package:saefra_run/core/widgets/secondary_button.dart';
import 'package:saefra_run/generated/assets.dart';

class AddEmergencyContactScreen extends StatefulWidget {
  const AddEmergencyContactScreen({super.key});

  @override
  State<AddEmergencyContactScreen> createState() =>
      _AddEmergencyContactScreenState();
}

class _AddEmergencyContactScreenState extends State<AddEmergencyContactScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _importFromContacts() async {
    final contactService = context.read<ContactService>();
    var picked = await contactService.pickFromDevice();

    if (!mounted) return;

    if (picked != null) {
      _name.text = picked.name;
      _phone.text = picked.phone;
      return;
    }

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

    if (picked != null) {
      _name.text = picked.name;
      _phone.text = picked.phone;
      return;
    }

    if (!mounted) return;
    final status = contactService.statusMessage;
    if (status != null &&
        status.contains('blocked') &&
        mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(status),
          action: SnackBarAction(
            label: 'Settings',
            onPressed: contactService.openAppSettingsForContacts,
          ),
        ),
      );
    }
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty || _phone.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    final settings = context.read<SettingsService>();
    final ok = await settings.addContact(_name.text.trim(), _phone.text.trim());
    if (!mounted) return;

    if (ok) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text(
            'Contact Added Successfully',
            style: Theme.of(ctx).textTheme.titleMedium,
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text('Done'),
            ),
          ],
        ),
      );
      if (mounted) context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(settings.error ?? 'Failed to add contact')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final contactService = context.watch<ContactService>();
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const AppPageHeader(title: 'Add Contact'),
            Expanded(
              child: ListView(
                padding: EdgeInsets.all(16.w),
                children: [
                  Center(
                    child: Image.asset(
                      Assets.settingsEmergencyIcon,
                      width: 72.w,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.contact_emergency,
                        size: 72.sp,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  SecondaryButton(
                    label: contactService.isLoading
                        ? 'Opening Contacts...'
                        : 'Import from Contacts',
                    onPressed:
                        contactService.isLoading ? null : _importFromContacts,
                  ),
                  if (contactService.statusMessage != null) ...[
                    SizedBox(height: 8.h),
                    Text(
                      contactService.statusMessage!,
                      textAlign: TextAlign.center,
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                  SizedBox(height: 24.h),
                  Text('Name', style: textTheme.bodySmall),
                  SizedBox(height: 6.h),
                  AppTextField(controller: _name),
                  SizedBox(height: 16.h),
                  Text('Phone Number', style: textTheme.bodySmall),
                  SizedBox(height: 6.h),
                  AppTextField(
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(16.w),
              child: PrimaryButton(
                label: 'Save Contact',
                onPressed: _save,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
