import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:saefra_run/core/constants/app_colors.dart';
import 'package:saefra_run/core/services/auth_service.dart';
import 'package:saefra_run/core/widgets/app_text_field.dart';
import '../../../core/utils/app_validators.dart';
import '../../../core/widgets/auth_header.dart';
import '../../../generated/assets.dart';
import '../../onboarding/widgets/common_app_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthService>();
    final success = await auth.login(
      identifier: _identifierController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      context.goNamed('gender');
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
      body: SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          physics: const BouncingScrollPhysics(),
          children: [
            AuthHeader(
              title: 'Log in',
              subtitle: 'Please sign in to continue',
              fallbackRoute: '/onboarding/intro',
            ),
          SizedBox(height: 18.h,),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 10.w),
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
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
                  const SizedBox(height: 18),
                  AppTextField(
                    controller: _passwordController,
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
                    SizedBox(height: 8.h),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: InkWell(
                      onTap: (){
                        context.pushNamed('forgotPassword');
                        },
                      child: Text('Forgot Password?',style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w400,
                          fontSize: 14.sp
                      )),
                    ),
                  ),
                    SizedBox(height: 17.h),
                  AppPrimaryButton(
                    label: 'Login',
                    onTap: _login,
                  ),
                    SizedBox(height: 16.h),
                  Image.asset(Assets.socLogin,scale: 2.3,),
                  SizedBox(height: 18.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      InkWell(
                        onTap: (){
                          auth.googleLogin();
                        },
                          child: Image.asset(Assets.googleLogo,scale: 2.6,)
                      ),
                      if (Platform.isIOS) Image.asset(Assets.aapleLogo, scale: 2.6) else const SizedBox.shrink()
                    ],
                  ),
                  SizedBox(height: 5.h,),
                  Center(
                    child: Text.rich(
                      TextSpan(
                        text: 'Don’t have an account? ',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w400,
                          fontSize: 14.sp,
                        ),
                        children: [
                          TextSpan(
                            text: 'Sign Up',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 14.sp,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                context.pushNamed('signup');
                                },
                          ),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
        ),
      ),
    );
  }
}
