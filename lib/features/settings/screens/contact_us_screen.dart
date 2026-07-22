import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:saefra_run/core/constants/app_colors.dart';
import 'package:saefra_run/core/services/settings_service.dart';
import 'package:saefra_run/core/utils/navigation_utils.dart';
import 'package:saefra_run/core/widgets/app_page_header.dart';
import 'package:saefra_run/core/widgets/app_text_field.dart';
import 'package:saefra_run/core/widgets/primary_button.dart';
import 'package:saefra_run/core/utils/app_validators.dart';
import 'package:saefra_run/features/settings/widgets/contact_sent_dialog.dart';
import 'package:saefra_run/generated/assets.dart';

class ContactUsScreen extends StatefulWidget {
  const ContactUsScreen({super.key});

  @override
  State<ContactUsScreen> createState() => _ContactUsScreenState();
}

class _ContactUsScreenState extends State<ContactUsScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _email;
  late final TextEditingController _message;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsService>();
    final displayName = settings.firstName.isNotEmpty
        ? '${settings.firstName} ${settings.lastName}'.trim()
        : 'User';
    _name = TextEditingController(text: displayName);
    _email = TextEditingController(text: settings.email);
    _message = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<SettingsService>().load();
      if (!mounted) return;
      final loaded = context.read<SettingsService>();
      final name = loaded.firstName.isNotEmpty
          ? '${loaded.firstName} ${loaded.lastName}'.trim()
          : _name.text;
      _name.text = name;
      _email.text = loaded.email;
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSending = true);
    await Future<void>.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    setState(() => _isSending = false);

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (ctx) => ContactSentDialog(
        onDone: () {
          Navigator.pop(ctx);
          if (mounted) safePop(context, fallback: '/settings');
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const AppPageHeader(title: 'Contact Us'),
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                children: [
                  SizedBox(height: 8.h),
                  Center(
                    child: Image.asset(
                      Assets.IIcon,
                      width: 150.w,
                      height: 150.w,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.info_outline,
                        color: AppColors.primary,
                        size: 48.sp,
                      ),
                    ),
                  ),
                  SizedBox(height: 20.h),
                  Text(
                    'Please enter your information for query to the admin',
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium?.copyWith(
                      fontSize: 14.sp,
                      height: 1.45,
                    ),
                  ),
                  SizedBox(height: 24.h),
                  Form(
                    key: _formKey,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    child: Column(
                      children: [
                        _ContactField(
                          label: 'Name',
                          controller: _name,
                          textTheme: textTheme,
                          validator: (value) =>
                              AppValidators.required(value, 'Name'),
                        ),
                        SizedBox(height: 16.h),
                        _ContactField(
                          label: 'Email',
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          textTheme: textTheme,
                          validator: AppValidators.email,
                        ),
                        SizedBox(height: 16.h),
                        _ContactField(
                          label: 'Message',
                          controller: _message,
                          hint: 'Enter Message',
                          maxLines: 5,
                          textTheme: textTheme,
                          validator: AppValidators.message,
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
                  PrimaryButton(
                    label: 'Send Message',
                    isLoading: _isSending,
                    onPressed: _sendMessage,
                  ),
                  SizedBox(height: 10.h),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _isSending ? null : () => safePop(context, fallback: '/settings'),
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

class _ContactField extends StatelessWidget {
  const _ContactField({
    required this.label,
    required this.controller,
    required this.textTheme,
    this.keyboardType,
    this.hint,
    this.maxLines = 1,
    this.validator,
  });

  final String label;
  final TextEditingController controller;
  final TextTheme textTheme;
  final TextInputType? keyboardType;
  final String? hint;
  final int maxLines;
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
        if (maxLines > 1)
          TextFormField(
            controller: controller,
            maxLines: maxLines,
            validator: validator,
            style: textTheme.bodyLarge?.copyWith(fontSize: 14.sp),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: textTheme.bodyMedium?.copyWith(fontSize: 14.sp),
              filled: true,
              fillColor: const Color(0xFF1C1C1C),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 20.w,
                vertical: 16.h,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.r),
                borderSide: const BorderSide(color: Colors.white),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.r),
                borderSide: const BorderSide(color: Colors.white),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.r),
                borderSide: const BorderSide(color: AppColors.error),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.r),
                borderSide: const BorderSide(color: AppColors.error),
              ),
            ),
          )
        else
          AppTextField(
            controller: controller,
            keyboardType: keyboardType,
            hint: hint,
            validator: validator,
          ),
      ],
    );
  }
}
