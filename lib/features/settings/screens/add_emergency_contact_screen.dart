import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:saefra_run/core/constants/app_colors.dart';
import 'package:saefra_run/core/services/contact_service.dart';
import 'package:saefra_run/core/services/settings_service.dart';
import 'package:saefra_run/core/utils/app_validators.dart';
import 'package:saefra_run/core/utils/navigation_utils.dart';
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
  static const _maxImageBytes = 2 * 1024 * 1024;
  static const _allowedExtensions = {'jpg', 'jpeg', 'png', 'gif'};

  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _imagePicker = ImagePicker();

  String? _apiError;
  String? _imagePath;
  String? _imageError;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    setState(() {
      _imageError = null;
      _apiError = null;
    });

    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );
    if (!mounted || picked == null) return;

    final extension = picked.path.split('.').last.toLowerCase();
    if (!_allowedExtensions.contains(extension)) {
      setState(() {
        _imageError = 'Image must be JPG, JPEG, PNG, or GIF.';
        _imagePath = null;
      });
      return;
    }

    final size = await File(picked.path).length();
    if (size > _maxImageBytes) {
      setState(() {
        _imageError = 'Image must be 2 MB or smaller.';
        _imagePath = null;
      });
      return;
    }

    setState(() {
      _imagePath = picked.path;
      _imageError = null;
    });
  }

  void _removeImage() {
    setState(() {
      _imagePath = null;
      _imageError = null;
    });
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
    if (!_formKey.currentState!.validate()) return;
    if (_imageError != null) return;

    setState(() => _apiError = null);

    final settings = context.read<SettingsService>();
    final ok = await settings.addContact(
      _name.text.trim(),
      _phone.text.trim(),
      imagePath: _imagePath,
    );
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
      if (mounted) safePop(context, fallback: '/settings/emergency-contacts');
    } else {
      setState(() {
        _apiError = settings.error ?? 'Failed to add contact';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final contactService = context.watch<ContactService>();
    final settings = context.watch<SettingsService>();
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
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 44.r,
                            backgroundColor: AppColors.surface,
                            backgroundImage: _imagePath != null
                                ? FileImage(File(_imagePath!))
                                : null,
                            child: _imagePath == null
                                ? Image.asset(
                                    Assets.settingsEmergencyIcon,
                                    width: 40.w,
                                    errorBuilder: (_, __, ___) => Icon(
                                      Icons.contact_emergency,
                                      size: 40.sp,
                                      color: AppColors.primary,
                                    ),
                                  )
                                : null,
                          ),
                          Container(
                            width: 30.w,
                            height: 30.w,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.background,
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              _imagePath == null
                                  ? Icons.add_a_photo_outlined
                                  : Icons.edit_outlined,
                              color: AppColors.white,
                              size: 16.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Optional photo (max 2 MB, JPG/PNG/GIF)',
                    textAlign: TextAlign.center,
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                  if (_imagePath != null) ...[
                    SizedBox(height: 8.h),
                    Center(
                      child: TextButton(
                        onPressed: _removeImage,
                        child: const Text('Remove Photo'),
                      ),
                    ),
                  ],
                  if (_imageError != null) ...[
                    SizedBox(height: 4.h),
                    Text(
                      _imageError!,
                      textAlign: TextAlign.center,
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ],
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
                  Form(
                    key: _formKey,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Name', style: textTheme.bodySmall),
                        SizedBox(height: 6.h),
                        AppTextField(
                          controller: _name,
                          validator: (value) =>
                              AppValidators.required(value, 'Name'),
                        ),
                        SizedBox(height: 16.h),
                        Text('Phone Number', style: textTheme.bodySmall),
                        SizedBox(height: 6.h),
                        AppTextField(
                          controller: _phone,
                          keyboardType: TextInputType.phone,
                          validator: AppValidators.phone,
                        ),
                        if (_apiError != null) ...[
                          SizedBox(height: 12.h),
                          Text(
                            _apiError!,
                            style: textTheme.bodySmall?.copyWith(
                              color: AppColors.error,
                              fontSize: 12.sp,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(16.w),
              child: PrimaryButton(
                label: settings.isLoading ? 'Saving...' : 'Save Contact',
                onPressed: settings.isLoading ? null : _save,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
