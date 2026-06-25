import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:saefra_run/core/services/auth_service.dart';
import 'package:saefra_run/core/widgets/app_text_field.dart';
import 'package:saefra_run/core/widgets/auth_scaffold.dart';
import 'package:saefra_run/core/widgets/primary_button.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/app_validators.dart';
import '../../../core/widgets/auth_header.dart';
import '../../../generated/assets.dart';
import '../../onboarding/widgets/common_app_button.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();

  @override
  void dispose() {
    _identifierController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthService>();
    final success = await auth.forgotPassword(
      identifier: _identifierController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      context.pushNamed('verification');
    } else if (auth.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error!)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();

    return Scaffold(
      body: Column(
        children: [
          AuthHeader(
            title: "Forgot Password?",
            subtitle: "Enter your registered email id to reset the password",
          ),
          Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Padding(
              padding:   EdgeInsets.symmetric(horizontal: 10.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppTextField(
                    keyboardType: TextInputType.emailAddress,
                    controller: _identifierController,
                    hint: "testel@gmail.com",
                    prefixIcon: AppFieldPrefixIcon(
                      icon: Image.asset(Assets.imagesEmail,scale: 2.5,),
                    ),
                    validator: AppValidators.email,
                  ),
                    SizedBox(height: 24.h),
                  AppPrimaryButton(
                    label: 'Submit',
                    onTap: _send,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
