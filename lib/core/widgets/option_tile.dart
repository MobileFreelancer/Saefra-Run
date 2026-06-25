import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class OptionTile extends StatelessWidget {
  const OptionTile({
    super.key,
    required this.title,
    required this.isSelected,
    required this.onTap,
    this.subtitle,
    this.width,
    this.height,
    this.imagePath, // Custom asset image path configuration replacing standard icons
    this.showTextField = false,
    this.textFieldController,
    this.dividerHeight = 25,
    this.textFieldHint,
  });

  final String title;
  final String? subtitle;
  final String? imagePath;
  final bool isSelected;
  final double? width;
  final double? height;
  final VoidCallback onTap;
  final bool showTextField;
  final double dividerHeight;
  final TextEditingController? textFieldController;
  final String? textFieldHint;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.backgroundBlackTra,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary: const Color(0xFF222222),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color:AppColors.primary.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ]
              : null,
        ),
        child: Row(
          children: [
            if (imagePath != null) ...[
              SizedBox(
                width: width ??32,
                height: height ??32,
                child: Image.asset(
                  imagePath!,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.person,
                    color: Colors.white54,
                  ),
                ),
              ),
              const SizedBox(width: 16),
            ],
            SizedBox(
                height: dividerHeight,
                width: 10,
                child: VerticalDivider(color: AppColors.white.withAlpha(30),)),
            const SizedBox(width: 16),

            Expanded(
              child: showTextField
                  ? TextField(
                controller: textFieldController,
                onTap: onTap,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w400,
                  fontSize: 15,
                ),
                decoration: InputDecoration(
                  isDense: true,
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  hintText: textFieldHint ?? title,
                  hintStyle: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w400,
                    fontSize: 15,
                  ),
                ),
              )
                  : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: Colors.white,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      style: TextStyle(color:Colors.white, fontSize: 12),
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
        boxShadow: isSelected
            ? [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.28),
            blurRadius: 13.2,
            spreadRadius: 0,
            offset: Offset(1,1)
          ),
        ]
            : [],
        border: Border.all(
          color: isSelected ? AppColors.primary : AppColors.border,
          width: 1.5,
        ),
      ),
      alignment: Alignment.center,
      child: isSelected
          ? const Icon(Icons.circle, size: 16, color: AppColors.white)
          : null,
    );
  }
}