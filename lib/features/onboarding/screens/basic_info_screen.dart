import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:saefra_run/core/constants/app_colors.dart';
import 'package:saefra_run/core/services/onboarding_service.dart';
import 'package:saefra_run/core/widgets/onboarding_progress_widgets.dart';
import 'package:saefra_run/features/onboarding/widgets/onboarding_input_field.dart';
import 'package:saefra_run/generated/assets.dart';

import '../../../core/widgets/app_text_field.dart';

class BasicInfoScreen extends StatefulWidget {
  const BasicInfoScreen({super.key});

  @override
  State<BasicInfoScreen> createState() => _BasicInfoScreenState();
}

class _BasicInfoScreenState extends State<BasicInfoScreen> {
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;

  @override
  void initState() {
    super.initState();
    final data = context.read<OnboardingService>().data;
    _firstNameController = TextEditingController(text: data.firstName ?? '');
    _lastNameController = TextEditingController(text: data.lastName ?? '');
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  String _formatBirthdate(DateTime? date) {
    if (date == null) return '';
    final mm = date.month.toString().padLeft(2, '0');
    final dd = date.day.toString().padLeft(2, '0');
    return '$mm/$dd/${date.year}';
  }

  Future<void> _pickBirthdate(OnboardingService onboarding) async {
    final now = DateTime.now();
    final initial = onboarding.data.dateOfBirth ??
        DateTime(now.year - 25, now.month, now.day);

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 100),
      lastDate: DateTime(now.year - 13, now.month, now.day),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              onPrimary: AppColors.white,
              surface: AppColors.backgroundBlackTra,
              onSurface: AppColors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      onboarding.setDateOfBirth(picked);
    }
  }

  void _continue(OnboardingService onboarding) {
    onboarding.setFirstName(_firstNameController.text.trim());
    onboarding.setLastName(_lastNameController.text.trim());
    if (onboarding.data.dateOfBirth == null) return;
    context.go('/onboarding/activity-level');
  }

  @override
  Widget build(BuildContext context) {
    final onboarding = context.watch<OnboardingService>();
    final data = onboarding.data;
    final textTheme = Theme.of(context).textTheme;
    final birthLabel = _formatBirthdate(data.dateOfBirth);

    final canContinue = (data.firstName?.trim().isNotEmpty ?? false) &&
        (data.lastName?.trim().isNotEmpty ?? false) &&
        data.dateOfBirth != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            OnboardingStepHeader(
              step: 2,
              totalSteps: 4,
              onBack: () => context.go('/onboarding/gender'),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 10.h),
                    Center(
                      child: Text(
                        "Let's Get to Know You",
                        style: textTheme.displayLarge?.copyWith(
                          fontSize: 22.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      'Tell us a little about yourself so we can personalize your Saefra experience.',
                      style: textTheme.bodySmall?.copyWith(
                          fontSize: 13.sp,
                          height: 1.45,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w400
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 28.h),
                    Text(
                      'Basic Information',
                      style: textTheme.displayLarge?.copyWith(fontSize: 15.sp,fontWeight: FontWeight.w700),
                    ),
                    SizedBox(height: 12.h),
                    AppTextField(
                      keyboardType: TextInputType.text,
                      controller: _firstNameController,
                      hint: "Enter first name ",
                      onChanged: onboarding.setFirstName,
                      prefixIcon: AppFieldPrefixIcon(
                        icon: Image.asset(Assets.user,scale: 2.5,),
                      ),
                    ),
                    SizedBox(height: 12.h),
                    AppTextField(
                      keyboardType: TextInputType.text,
                      controller: _lastNameController,
                      hint: "Enter Last Name  ",
                      onChanged: onboarding.setLastName,
                      prefixIcon: AppFieldPrefixIcon(
                        icon: Image.asset(Assets.user,scale: 2.5,),
                      ),
                    ),
                    SizedBox(height: 12.h),
                    GestureDetector(
                      onTap: () => _pickBirthdate(onboarding),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 14.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundBlackTra,
                          borderRadius: BorderRadius.circular(28.r),
                          border: Border.all(color: AppColors.textBorder),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today_outlined,
                              color: AppColors.white,
                              size: 20.sp,
                            ),
                            SizedBox(width: 12.w),
                            Container(
                              height: 20.h,
                              width: 1,
                              color: const Color(0xFF333333),
                            ),
                            SizedBox(width: 16.w),
                            Expanded(
                              child: Text(
                                birthLabel.isEmpty ? 'mm/dd/yyyy' : birthLabel,
                                style: textTheme.bodyLarge?.copyWith(
                                  fontSize: 15.sp,
                                  color: birthLabel.isEmpty
                                      ? AppColors.textThird
                                      : AppColors.white,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 20.h),
                    Container(
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundBlackTra,
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(color: AppColors.textBorder),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 52.w,
                            height: 52.w,
                            child: Image.asset(
                              Assets.onboardingCakeIcon,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) => Icon(
                                Icons.cake_outlined,
                                color: AppColors.primary,
                                size: 36.sp,
                              ),
                            ),
                          ),
                          SizedBox(width: 14.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Why We ask',
                                  style: textTheme.titleMedium?.copyWith(
                                    fontSize: 15.sp,
                                  ),
                                ),
                                SizedBox(height: 4.h),
                                Text(
                                  'Your birthdate helps us tailor your training plan and recommendations that best suit your needs.',
                                  style: textTheme.bodySmall?.copyWith(
                                    fontSize: 12.sp,
                                    height: 1.4,
                                    color: AppColors.textThird,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            OnboardingContinueBar(
              isEnabled: canContinue,
              onContinue: () => _continue(onboarding),
              onSkip: () => context.go('/onboarding/activity-level'),
            ),
          ],
        ),
      ),
    );
  }
}
