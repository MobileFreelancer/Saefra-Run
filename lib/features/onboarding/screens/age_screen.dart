import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:saefra_run/core/constants/app_colors.dart';
import 'package:saefra_run/core/services/onboarding_service.dart';
import 'package:saefra_run/core/widgets/onboarding_nav_bar.dart';
import 'package:saefra_run/features/onboarding/widgets/onboarding_step_scaffold.dart';

class AgeScreen extends StatefulWidget {
  const AgeScreen({super.key});

  @override
  State<AgeScreen> createState() => _AgeScreenState();
}

class _AgeScreenState extends State<AgeScreen> {
  late FixedExtentScrollController _scrollController;
  int _selectedAge = 36;

  @override
  void initState() {
    super.initState();
    final savedAge = context.read<OnboardingService>().data.age;
    _selectedAge = savedAge ?? 36;
    _scrollController = FixedExtentScrollController(
      initialItem: _selectedAge - 13,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingStepScaffold(
      title: 'How old are you?',
      bottomNavigationBar: OnboardingNavBar(
        onBack: () => context.go('/onboarding/goal'),
        onNext: () {
          context.read<OnboardingService>().setAge(_selectedAge);
          context.go('/onboarding/location');
        },
      ),
      child: SizedBox(
        height: 280,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              height: 56,
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                border: const Border(
                  top: BorderSide(color: AppColors.primary, width: 2),
                  bottom: BorderSide(color: AppColors.primary, width: 2),
                ),
                color: AppColors.primary.withValues(alpha: 0.08),
              ),
            ),
            CupertinoPicker(
              scrollController: _scrollController,
              itemExtent: 48,
              magnification: 1.1,
              squeeze: 1.1,
              useMagnifier: true,
              onSelectedItemChanged: (index) {
                setState(() => _selectedAge = index + 13);
              },
              children: List.generate(88, (index) {
                final age = index + 13;
                final isSelected = age == _selectedAge;
                return Center(
                  child: Text(
                    '$age',
                    style: TextStyle(
                      fontSize: isSelected ? 32 : 20,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w400,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textMuted,
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
