import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:saefra_run/core/constants/app_colors.dart';
import 'package:saefra_run/core/services/auth_service.dart';
import 'package:saefra_run/core/widgets/app_text_field.dart';
import '../../../core/utils/app_tost.dart';
import '../../../core/utils/app_validators.dart';
import '../../../core/widgets/auth_header.dart';
import '../../../generated/assets.dart';
import '../../onboarding/widgets/common_app_button.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _conformPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _agreedToTerms = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthService>();

    if (!auth.agreedToTerms) {
      AppToast.error('Please accept Terms & Conditions');
      return;
    }

    auth.startSignup(
      email: _nameController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;
    context.go('/onboarding/gender');
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
              title: 'Register',
              subtitle: 'Please sign in to continue',
              fallbackRoute: '/onboarding/intro',
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 10.w),
              child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppTextField(
                    keyboardType: TextInputType.emailAddress,
                    controller: _nameController,
                    hint: "testel@gmail.com",
                    prefixIcon: AppFieldPrefixIcon(
                      icon: Image.asset(Assets.imagesEmail,scale: 2.5,),
                    ),
                    validator: AppValidators.email,
                  ),
                    SizedBox(height: 16.h),
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

                  SizedBox(height: 5  .h,),
                  Padding(
                    padding:   EdgeInsets.symmetric(horizontal: 7.w),
                    child: Text("Min-8 chars, uppercase & special.",style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w400,
                        fontSize: 12.sp
                    ),),
                  ),
                  SizedBox(height: 15.h),
                  AppTextField(
                    controller: _conformPasswordController,
                    hint: "Re-enter Password",
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
                        return "Please Re-enter password";
                      }
                      else if(_passwordController.text.trim()!=_conformPasswordController.text.trim()){
                        return "Password don't matched";
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 10.h),
                  Row(
                    children: [
                      Checkbox(
                        value: auth.agreedToTerms,
                        onChanged: (value) {
                          auth.setTerms(value ?? false);
                        },
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: auth.toggleTerms,
                          child: Text(
                            'Accept with Terms & Conditions',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                              fontSize: 14.sp,
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  AppPrimaryButton(
                    label: 'Register',
                    onTap: () {
                      if (!_formKey.currentState!.validate()) return;
                      if (!auth.agreedToTerms) {
                        AppToast.error('Please accept Terms & Conditions');
                        return;
                      }
                      _register();
                    },
                  ),
                  SizedBox(height: 18.h,),
                  Center(child: Image.asset(Assets.socTitle,scale: 2.3,)),
                  SizedBox(height: 18.h,),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(Assets.googleLogo,scale: 2.6,),
                     Platform.isIOS?Image.asset(Assets.aapleLogo,scale: 2.6,):SizedBox.shrink()
                    ],
                  ),
                  SizedBox(height: 5.h,),
                  Center(
                    child: Text.rich(
                      TextSpan(
                        text: 'Already have an account? ',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w400,
                          fontSize: 14.sp,
                        ),
                        children: [
                          TextSpan(
                            text: 'Login',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 14.sp,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                context.goNamed('login');
                              },
                          ),
                        ],
                      ),
                    ),
                  )

                ],
              ),
            ),
              ), ],
        ),
      ),
    );
  }
}
