import 'package:flutter/material.dart';
import 'package:saefra_run/core/constants/app_colors.dart';

/// Shows [assetPath] when the file exists; otherwise [fallbackIcon].
/// Add the PNG/SVG at [assetPath] later — it will appear automatically.
class AppAssetIcon extends StatelessWidget {
  const AppAssetIcon({
    super.key,
    required this.assetPath,
    required this.fallbackIcon,
    this.size = 24,
    this.color,
    this.fit = BoxFit.contain,
  });

  final String assetPath;
  final IconData fallbackIcon;
  final double size;
  final Color? color;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      width: size,
      height: size,
      fit: fit,
      color: color,
      errorBuilder: (_, __, ___) => Icon(
        fallbackIcon,
        size: size,
        color: color ?? AppColors.textPrimary,
      ),
    );
  }
}
