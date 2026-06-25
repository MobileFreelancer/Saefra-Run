import 'package:flutter/material.dart';
import 'package:saefra_run/core/constants/app_colors.dart';

/// A reusable selectable list tile used across onboarding screens
/// (Gender, Activity Level, Goal, etc).
///
/// Supports three layouts depending on what's passed in:
/// - icon only            -> compact row (e.g. gender options)
/// - icon + subtitle       -> taller row (e.g. activity level options)
/// - no icon, icon only on selected state -> simple list (e.g. goal options)
class OptionTile extends StatelessWidget {
  const OptionTile({
    super.key,
    required this.title,
    required this.isSelected,
    required this.onTap,
    this.subtitle,
    this.icon,
    this.showTextField = false,
    this.textFieldController,
    this.textFieldHint,
  });

  /// Main label of the option.
  final String title;

  /// Optional secondary line shown under the title.
  final String? subtitle;

  /// Optional leading icon. When null, no leading icon is rendered.
  final IconData? icon;

  final bool isSelected;
  final VoidCallback onTap;

  /// When true, renders an inline text field instead of plain text for the
  /// title row (used by "Prefer to self-identify as ..." style options).
  final bool showTextField;
  final TextEditingController? textFieldController;
  final String? textFieldHint;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.12)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.18)
                      : AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 14),
            ],
            Expanded(
              child: showTextField
                  ? TextField(
                      controller: textFieldController,
                      onTap: onTap,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                      decoration: InputDecoration(
                        isDense: true,
                        filled: false,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        hintText: textFieldHint ?? title,
                        hintStyle:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: AppColors.textMuted,
                                  fontWeight: FontWeight.w500,
                                ),
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.textPrimary,
                                  ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 3),
                          Text(
                            subtitle!,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ],
                    ),
            ),
            const SizedBox(width: 12),
            _RadioDot(isSelected: isSelected),
          ],
        ),
      ),
    );
  }
}

class _RadioDot extends StatelessWidget {
  const _RadioDot({required this.isSelected});

  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isSelected ? AppColors.primary : AppColors.transparent,
        border: Border.all(
          color: isSelected ? AppColors.primary : AppColors.border,
          width: 1.5,
        ),
      ),
      child: isSelected
          ? const Icon(Icons.circle, size: 16, color: AppColors.white)
          : null,
    );
  }
}
