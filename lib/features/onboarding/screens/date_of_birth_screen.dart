import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:saefra_run/core/constants/app_colors.dart';
import 'package:saefra_run/core/services/onboarding_service.dart';
import 'package:saefra_run/core/widgets/onboarding_progress_widgets.dart';

import '../../../generated/assets.dart'; // Point correctly to where Assets is stored

class DateOfBirthScreen extends StatefulWidget {
  const DateOfBirthScreen({super.key});

  @override
  State<DateOfBirthScreen> createState() => _DateOfBirthScreenState();
}

class _DateOfBirthScreenState extends State<DateOfBirthScreen> {
  DateTime? _dateOfBirth;
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final saved = context.read<OnboardingService>().data.dateOfBirth;
    _dateOfBirth = saved;
    _controller = TextEditingController(text: _format(saved));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _format(DateTime? date) {
    if (date == null) return '';
    final mm = date.month.toString().padLeft(2, '0');
    final dd = date.day.toString().padLeft(2, '0');
    return '$mm/$dd/${date.year}';
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(now.year - 25, now.month, now.day),
      firstDate: DateTime(now.year - 100),
      lastDate: DateTime(now.year - 13, now.month, now.day),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFEF4444),
              onPrimary: Colors.white,
              surface: Color(0xFF141414),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dateOfBirth = picked;
        _controller.text = _format(picked);
      });
    }
  }

  void _continue() {
    if (_dateOfBirth == null) return;
    context.read<OnboardingService>().setDateOfBirth(_dateOfBirth!);
    context.go('/onboarding/location');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D), // Matches dark layout theme of image_301c6c.png
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            OnboardingStepHeader(
              step: 4,
              totalSteps: 4,
              onBack: () => context.go('/onboarding/goal'),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center, // Centered alignment
                  children: [
                    const SizedBox(height: 10),
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                        ),
                        children: const [
                          TextSpan(text: 'When were you '),
                          TextSpan(
                            text: 'Born?',
                            style: TextStyle(color:AppColors.primary), // Accent crimson red
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'This helps us personalize your experience and track your\nprogress routes.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.white,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 36),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Date of Birth',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: AppColors.white,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: _pickDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundBlackTra,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFF222222)),
                        ),
                        child: Row(
                          children: [
                            Image.asset(
                              Assets.onboardingConsistencyIcon,
                              fit: BoxFit.contain,
                              width: 20,
                              errorBuilder: (_, __, ___) =>  Icon(
                                Icons.person,
                                color: AppColors.white,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              height: 20,
                              width: 1,
                              color: const Color(0xFF333333),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                _controller.text.isEmpty ? 'mm/dd/yyyy' : _controller.text,
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: _controller.text.isEmpty ?AppColors.textThird: AppColors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundBlackTra,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.textBorder),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 60,
                            height: 60,
                            child: Image.asset(
                              Assets.onboardingCakeIcon, // Customized cake icon asset hook mapping
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.cake_outlined,
                                color: AppColors.white,
                                size: 36,
                              ),
                            ),
                          ),
                          const SizedBox(width: 18),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                 Text(
                                  'Why We ask',
                                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                                    color: AppColors.white,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Your birthdate helps us tailor your training plan and recommendations that best suit your needs.',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textThird,
                                    fontSize: 12,
                                    height: 1.4,
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
              isEnabled: _dateOfBirth != null,
              onContinue: _continue,
              onSkip: () => context.go('/onboarding/location'),
            ),
          ],
        ),
      ),
    );
  }
}