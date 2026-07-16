import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:saefra_run/core/constants/app_colors.dart';
import 'package:saefra_run/core/models/emergency_contact_model.dart';

class EmergencyContactAvatar extends StatelessWidget {
  const EmergencyContactAvatar({
    super.key,
    required this.contact,
    this.radius = 22,
    this.fontSize,
  });

  final EmergencyContactModel contact;
  final double radius;
  final double? fontSize;

  @override
  Widget build(BuildContext context) {
    final initial = contact.name.trim().isNotEmpty
        ? contact.name.trim()[0].toUpperCase()
        : '?';
    final imageUrl = contact.resolvedImageUrl;
    final textStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
          fontSize: fontSize ?? 16.sp,
          fontWeight: FontWeight.w600,
        );
    final size = radius.r * 2;

    return ClipOval(
      child: Container(
        width: size,
        height: size,
        color: AppColors.surfaceLight,
        child: imageUrl != null
            ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Center(child: Text(initial, style: textStyle)),
              )
            : Center(child: Text(initial, style: textStyle)),
      ),
    );
  }
}
