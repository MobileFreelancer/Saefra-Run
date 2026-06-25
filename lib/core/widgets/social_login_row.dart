import 'package:flutter/material.dart';
import 'package:saefra_run/core/constants/app_colors.dart';

class SocialLoginRow extends StatelessWidget {
  const SocialLoginRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _SocialButton(
          icon: Icons.g_mobiledata,
          label: 'Google',
          onTap: () {},
        ),
        const SizedBox(width: 16),
        _SocialButton(
          icon: Icons.apple,
          label: 'Apple',
          onTap: () {},
        ),
        const SizedBox(width: 16),
        _SocialButton(
          icon: Icons.facebook,
          label: 'Facebook',
          onTap: () {},
        ),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(icon, color: AppColors.textPrimary, size: 28),
      ),
    );
  }
}
