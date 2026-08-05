import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:saefra_run/core/constants/app_colors.dart';
import 'package:saefra_run/core/services/auth_service.dart';
import 'package:saefra_run/core/services/settings_service.dart';
import 'package:saefra_run/core/utils/navigation_utils.dart';
import 'package:saefra_run/core/widgets/app_page_header.dart';
import 'package:saefra_run/core/widgets/app_text_field.dart';
import 'package:saefra_run/core/widgets/app_cached_image.dart';
import 'package:saefra_run/core/utils/app_validators.dart';
import 'package:saefra_run/core/widgets/primary_button.dart';
import 'package:image_picker/image_picker.dart';
import 'package:saefra_run/core/utils/app_tost.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _email;
  late final TextEditingController _phone;

  String _gender = 'Male';
  String _birthdate = '';
  String _runningLevel = 'Intermediate';
  String? _birthdateError;
  String? _apiError;
  String? _selectedProfileImagePath;
  static const _genders = ['Male', 'Female', 'Prefer not to say'];
  static const _runningLevels = ['Beginner', 'Intermediate', 'Advanced'];

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsService>();
    _firstName = TextEditingController(text: settings.firstName);
    _lastName = TextEditingController(text: settings.lastName);
    _email = TextEditingController(text: settings.email);
    _phone = TextEditingController(text: settings.phone);
    _gender = settings.gender;
    _birthdate = settings.birthdate;
    _runningLevel = settings.runningLevel;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<SettingsService>().load();
      if (!mounted) return;
      final loaded = context.read<SettingsService>();
      _firstName.text = loaded.firstName;
      _lastName.text = loaded.lastName;
      _email.text = loaded.email;
      _phone.text = loaded.phone;
      setState(() {
        _gender = loaded.gender;
        _birthdate = loaded.birthdate;
        _runningLevel = loaded.runningLevel;
      });
    });
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _pickBirthdate() async {
    final initial = _parseBirthdate() ?? DateTime(1996, 2, 20);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              surface: AppColors.surface,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked == null || !mounted) return;
    setState(() {
      _birthdate =
          '${picked.day.toString().padLeft(2, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.year}';
      _birthdateError = null;
    });
  }

  DateTime? _parseBirthdate() {
    if (_birthdate.isEmpty) return null;
    final parts = _birthdate.split('.');
    if (parts.length != 3) return null;
    return DateTime.tryParse('${parts[2]}-${parts[1]}-${parts[0]}',);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_birthdate.isEmpty) {
      setState(() => _birthdateError = 'Date of birth is required');
      return;
    }

    setState(() {
      _birthdateError = null;
      _apiError = null;
    });

    final settings = context.read<SettingsService>();

    settings.updateProfileFields(
      firstName: _firstName.text.trim(),
      lastName: _lastName.text.trim(),
      email: _email.text.trim(),
      phone: _phone.text.trim(),
      gender: _gender,
      birthdate: _birthdate,
      runningLevel: _runningLevel,
    );

   // AppLoader.show();

    final ok = await settings.saveProfile(
      profileImagePath: _selectedProfileImagePath,
    );

    //AppLoader.hide();

    if (!mounted) return;

    if (!ok) {
      setState(() => _apiError = settings.error ?? 'Save failed');
      return;
    }

    //AppToast.success('Profile updated successfully.');

    // Clear the selected image after successful upload
    _selectedProfileImagePath = null;

    safePop(context, fallback: '/settings');
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 85,
      );

      if (image == null || !mounted) return;
      log("imagePath--->${image.path}");
      setState(() {
        _selectedProfileImagePath = image.path;
        _apiError = null;
      });

      // Optional: Show preview immediately.
      //AppToast.success('Profile picture selected.');
    } catch (e) {
      if (mounted) {
        setState(() => _apiError = e.toString());
        AppToast.error('An error occurred: $e');
      }
    }
  }

  void _showImageSourceBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (BuildContext context) {
        final textTheme = Theme.of(context).textTheme;
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: AppColors.textMuted.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                ),
                SizedBox(height: 18.h),
                Text(
                  'Update Profile Picture',
                  textAlign: TextAlign.center,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    fontSize: 16.sp,
                  ),
                ),
                SizedBox(height: 24.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _ImageSourceOption(
                      icon: Icons.camera_alt_outlined,
                      label: 'Camera',
                      onTap: () {
                        Navigator.pop(context);
                        _pickImage(ImageSource.camera);
                      },
                    ),
                    _ImageSourceOption(
                      icon: Icons.photo_library_outlined,
                      label: 'Gallery',
                      onTap: () {
                        Navigator.pop(context);
                        _pickImage(ImageSource.gallery);
                      },
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();
    final auth = context.watch<AuthService>();
    final user = auth.currentUser;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const AppPageHeader(title: 'Profile'),
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                children: [
                  Text(
                    'Edit your profile to reflect the real you! Upload a new profile picture, and adjust contact details for a personalized touch.',
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium?.copyWith(
                      fontSize: 13.sp,
                      height: 1.45,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF888888),
                    ),
                  ),
                  SizedBox(height: 20.h),
                  Center(
                    child: GestureDetector(
                      onTap: () => _showImageSourceBottomSheet(context),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            padding: EdgeInsets.all(4.w),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.white.withValues(alpha: 0.15),
                                  blurRadius: 16.r,
                                  spreadRadius: 2.r,
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 60.r,
                              backgroundColor: AppColors.white,
                              child: _selectedProfileImagePath != null
                                  ? CircleAvatar(
                                      radius: 56.r,
                                      backgroundColor: AppColors.surfaceLight,
                                      backgroundImage:
                                          FileImage(File(_selectedProfileImagePath!)),
                                    )
                                  : (user?.profileImage != null && user!.profileImage!.isNotEmpty
                                      ? SizedBox(
                                          width: 112.r,
                                          height: 112.r,
                                          child: AppCircleCachedImage(
                                            imageUrl: user.profileImage!,
                                            width: 112.r,
                                            height: 112.r,
                                            fit: BoxFit.cover,
                                          ),
                                        )
                                      : CircleAvatar(
                                          radius: 56.r,
                                          backgroundColor: AppColors.surfaceLight,
                                          child: Icon(
                                            Icons.person,
                                            size: 48.sp,
                                            color: AppColors.textMuted,
                                          ),
                                        )),
                            ),
                          ),
                          Positioned(
                            right: 4.w,
                            bottom: 4.h,
                            child: Container(
                              width: 34.w,
                              height: 34.w,
                              decoration: const BoxDecoration(
                                color: AppColors.buttonColor,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.edit,
                                size: 16.sp,
                                color: AppColors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 24.h),
                  Form(
                    key: _formKey,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _ProfileField(
                                label: 'First Name',
                                controller: _firstName,
                                textTheme: textTheme,
                                validator: (value) =>
                                    AppValidators.required(value, 'First name'),
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: _ProfileField(
                                label: 'Last Name',
                                controller: _lastName,
                                textTheme: textTheme,
                                validator: (value) =>
                                    AppValidators.required(value, 'Last name'),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16.h),
                        _ProfileField(
                          label: 'Email',
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          textTheme: textTheme,
                          validator: AppValidators.email,
                        ),
                        SizedBox(height: 16.h),
                        _ProfileField(
                          label: 'Phone Number',
                          controller: _phone,
                          keyboardType: TextInputType.phone,
                          textTheme: textTheme,
                          validator: AppValidators.phone,
                        ),
                        SizedBox(height: 16.h),
                        Row(
                          children: [
                            Expanded(
                              child: _ProfileDropdown(
                                label: 'Gender',
                                value: _gender,
                                items: _genders,
                                textTheme: textTheme,
                                onChanged: (v) => setState(() => _gender = v),
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: _ProfilePickerField(
                                label: 'Date Of Birth',
                                value: _birthdate.isEmpty
                                    ? 'Select date'
                                    : _birthdate,
                                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 9.h),
                                icon: Icons.calendar_today_outlined,
                                textTheme: textTheme,
                                errorText: _birthdateError,
                                onTap: _pickBirthdate,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16.h),
                        _ProfileDropdown(
                          label: 'Running Level',
                          value: _runningLevel,
                          items: _runningLevels,
                          textTheme: textTheme,
                          onChanged: (v) => setState(() => _runningLevel = v),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
              child: Column(
                children: [
                  if (_apiError != null) ...[
                    Text(
                      _apiError!,
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.error,
                        fontSize: 12.sp,
                      ),
                    ),
                    SizedBox(height: 10.h),
                  ],
                  PrimaryButton(
                    label: 'Save Changes',
                    isLoading: settings.isLoading,
                    onPressed: _save,
                  ),
                  SizedBox(height: 10.h),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => safePop(context, fallback: '/settings'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.white,
                        side: const BorderSide(color: AppColors.white),
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28.r),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: textTheme.labelLarge?.copyWith(fontSize: 14.sp),
                      ),
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

class _ProfileField extends StatelessWidget {
  const _ProfileField({
    required this.label,
    required this.controller,
    required this.textTheme,
    this.keyboardType,
    this.validator,
  });

  final String label;
  final TextEditingController controller;
  final TextTheme textTheme;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: textTheme.bodySmall?.copyWith(fontSize: 12.sp),
        ),
        SizedBox(height: 6.h),
        AppTextField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
        ),
      ],
    );
  }
}

class _ProfileDropdown extends StatelessWidget {
  const _ProfileDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.textTheme,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> items;
  final TextTheme textTheme;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: textTheme.bodySmall?.copyWith(fontSize: 12.sp),
        ),
        SizedBox(height: 6.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C1C),
            borderRadius: BorderRadius.circular(30.r),
            border: Border.all(color: Colors.white54),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: items.contains(value) ? value : items.first,
              isExpanded: true,
              dropdownColor: AppColors.surface,
              icon: Icon(Icons.keyboard_arrow_down, color: AppColors.white, size: 20.sp),
              style: textTheme.bodyLarge?.copyWith(fontSize: 14.sp),
              items: items
                  .map(
                    (item) => DropdownMenuItem(
                      value: item,
                      child: Text(item),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null) onChanged(v);
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfilePickerField extends StatelessWidget {
  const _ProfilePickerField({
    required this.label,
    required this.value,
    required this.icon,
    required this.textTheme,
    required this.onTap,
    this.errorText,
    this.padding,
  });

  final String label;
  final String value;
  final IconData icon;
  final EdgeInsetsGeometry? padding;
  final TextTheme textTheme;
  final VoidCallback onTap;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: textTheme.bodySmall?.copyWith(fontSize: 12.sp),
        ),
        SizedBox(height: 6.h),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding:padding?? EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C1C),
              borderRadius: BorderRadius.circular(30.r),
              border: Border.all(
                color: errorText != null ? AppColors.error : Colors.white54,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: textTheme.bodyLarge?.copyWith(fontSize: 14.sp),
                  ),
                ),
                Icon(icon, color: AppColors.white, size: 18.sp),
              ],
            ),
          ),
        ),
        if (errorText != null) ...[
          SizedBox(height: 6.h),
          Text(
            errorText!,
            style: textTheme.bodySmall?.copyWith(
              color: AppColors.error,
              fontSize: 12.sp,
            ),
          ),
        ],
      ],
    );
  }
}

class _ImageSourceOption extends StatelessWidget {
  const _ImageSourceOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        width: 120.w,
        padding: EdgeInsets.symmetric(vertical: 20.h),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: AppColors.white.withValues(alpha: 0.05),
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32.sp,
              color: AppColors.buttonColor,
            ),
            SizedBox(height: 8.h),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
