import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:saefra_run/core/constants/app_colors.dart';
import 'package:saefra_run/core/services/auth_service.dart';
import 'package:saefra_run/core/widgets/app_text_field.dart';
import 'package:saefra_run/core/widgets/auth_scaffold.dart';
import 'package:saefra_run/core/widgets/primary_button.dart';
import 'package:saefra_run/core/widgets/social_login_row.dart';

import '../../../core/utils/app_tost.dart';
import '../../../core/utils/app_validators.dart';
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
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please agree to the Terms and Conditions'),
        ),
      );
      return;
    }

    final auth = context.read<AuthService>();
    final success = await auth.register(
      fullName: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      context.go('/dashboard');
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
      body: ListView(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        physics: BouncingScrollPhysics(),
        children: [
          SizedBox(height: 50.h,),
          Center(child: Image.asset(Assets.imagesLogowithtext,scale: 2.3,)),
          SizedBox(height: 8.h,),
          Center(
            child: Text("Register",style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 20.sp
            ),),
          ),
          SizedBox(height: 3.h,),
          Center(
            child: Text("Please sign in to continue",style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w400,
                fontSize: 14.sp
            ),),
          ),
          SizedBox(height: 20.h,),
          Padding(
            padding:   EdgeInsets.symmetric(horizontal: 10.w),
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
                    onTap: (){
                      if(_formKey.currentState!.validate()){
                        if(!auth.agreedToTerms){
                          AppToast.error('Please selected terms & condition');
                        }
                      }
                    },
                  ),
                  SizedBox(height: 18.h,),
                  Image.asset(Assets.socTitle),
                  SizedBox(height: 18.h,),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(Assets.googleLogo,scale: 2.6,),
                      Image.asset(Assets.aapleLogo,scale: 2.6,)
                    ],
                  ),
                  SizedBox(height: 5.h,),
                  Center(
                    child: Text.rich(
                      TextSpan(
                        text: 'Already have an account? ',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.border,
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
                                context.go('/login');
                              },
                          ),
                        ],
                      ),
                    ),
                  )

                ],
              ),
            ),
          )
        ],
      ),

    );
  }
}
