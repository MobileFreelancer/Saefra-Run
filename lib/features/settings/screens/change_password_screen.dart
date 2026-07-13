import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:saefra_run/core/constants/app_colors.dart';
import 'package:saefra_run/core/services/settings_service.dart';
import 'package:saefra_run/core/utils/app_validators.dart';
import 'package:saefra_run/core/widgets/app_text_field.dart';
import 'package:saefra_run/core/widgets/auth_header.dart';
import 'package:saefra_run/features/onboarding/widgets/common_app_button.dart';
import 'package:saefra_run/features/settings/widgets/password_changed_dialog.dart';
import 'package:saefra_run/generated/assets.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  String? _apiError;

  @override
  void dispose() {
    _current.dispose();
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _apiError = null);

    final settings = context.read<SettingsService>();
    final ok = await settings.changePassword(
      oldPassword: _current.text,
      newPassword: _new.text,
      confirmPassword: _confirm.text,
    );
    if (!mounted) return;

    if (!ok) {
      setState(() {
        _apiError = settings.error ?? 'Failed to change password';
      });
      return;
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (ctx) => PasswordChangedDialog(
        onDone: () {
          Navigator.pop(ctx);
          if (mounted) context.pop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Column(
            children: [
              AuthHeader(
                title: 'Reset Password',
                subtitle: 'Enter your new password to reset the password',
                fallbackRoute: '/settings',
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _PasswordField(
                          controller: _current,
                          hint: 'Current Password',
                          obscure: _obscureCurrent,
                          onToggleVisibility: () {
                            setState(() => _obscureCurrent = !_obscureCurrent);
                          },
                          validator: (value) =>
                              AppValidators.required(value, 'Current password'),
                        ),
                        SizedBox(height: 15.h),
                        _PasswordField(
                          controller: _new,
                          hint: 'New Password',
                          obscure: _obscureNew,
                          onToggleVisibility: () {
                            setState(() => _obscureNew = !_obscureNew);
                          },
                          validator: AppValidators.password,
                        ),
                        SizedBox(height: 15.h),
                        _PasswordField(
                          controller: _confirm,
                          hint: 'Confirm Password',
                          obscure: _obscureConfirm,
                          onToggleVisibility: () {
                            setState(
                              () => _obscureConfirm = !_obscureConfirm,
                            );
                          },
                          validator: (value) => AppValidators.confirmPassword(
                            value,
                            _new.text,
                          ),
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
                        SizedBox(height: 28.h),
                        AppPrimaryButton(
                          label: 'Submit',
                          isLoading: settings.isLoading,
                          onTap: settings.isLoading ? null : _submit,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.controller,
    required this.hint,
    required this.obscure,
    required this.onToggleVisibility,
    this.validator,
  });

  final TextEditingController controller;
  final String hint;
  final bool obscure;
  final VoidCallback onToggleVisibility;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: controller,
      hint: hint,
      obscureText: obscure,
      validator: validator,
      prefixIcon: AppFieldPrefixIcon(
        icon: Image.asset(
          Assets.imagesPassword,
          scale: 2.5,
        ),
      ),
      suffixIcon: IconButton(
        onPressed: onToggleVisibility,
        icon: Icon(
          obscure ? Icons.visibility_off : Icons.visibility,
          color: AppColors.white,
          size: 20.sp,
        ),
      ),
    );
  }
}
