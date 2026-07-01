import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:saefra_run/core/services/auth_service.dart';
import 'package:saefra_run/core/widgets/app_text_field.dart';
import '../../../core/utils/app_validators.dart';
import '../../../core/widgets/auth_header.dart';
import '../../../generated/assets.dart';
import '../../onboarding/widgets/common_app_button.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    print("++++++++++++++++++");
    try {
      if (!_formKey.currentState!.validate()) return;

      final auth = context.read<AuthService>();
      final success = await auth.resetPassword(
        newPassword: _newPasswordController.text,
        confirmPassword: _confirmPasswordController.text,
      );
print("++/////////////////$success");
      if (!mounted) return;

      if (success) {

        context.go('/auth/reset-password-successfully');
      } else if (auth.error != null) {

      }
    }  catch (e) {
      print("Error--->$e");
          }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 10.w),
          child: Column(
            children: [
              AuthHeader(
                title: 'Reset Password',
                subtitle: 'Enter your new password to reset the password',
                fallbackRoute: '/auth/verification',
              ),
            Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppTextField(
                    controller: _newPasswordController,
                    hint: "Password",
                    obscureText: auth.obscurePassword,
                    prefixIcon: AppFieldPrefixIcon(
                      icon: Image.asset(Assets.imagesPassword,scale: 2.5,),
                    ),
                    suffixIcon: IconButton(
                      onPressed: auth.togglePasswordVisibility,
                      icon: Icon(
                        auth.obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Colors.white,
                      ),
                    ),
                    validator: AppValidators.password,
                  ),
                  SizedBox(height: 15.h),
                  AppTextField(
                    controller: _confirmPasswordController,
                    hint: "Confirm Password",
                    obscureText: auth.obscureConfirmPassword,
                    prefixIcon: AppFieldPrefixIcon(
                      icon: Image.asset(Assets.imagesPassword,scale: 2.5,),
                    ),
                    suffixIcon: IconButton(
                      onPressed: auth.toggleConfirmPasswordVisibility,
                      icon: Icon(
                        auth.obscureConfirmPassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Colors.white,
                      ),
                    ),
                    validator: (value){
                      if(value==null||value.trim().isEmpty){
                        return "Please enter confirm password";
                      }
                      else if(_newPasswordController.text.trim()!=_confirmPasswordController.text.trim()){
                        return "Password don't matched";
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 22.h,),
                  AppPrimaryButton(
                    label: 'Submit',
                    onTap: _submit,
                  ),
                ],
              ),
            )
            ],
          ),
        ),
      ),
    );
  }
}
