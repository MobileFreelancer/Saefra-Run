import 'package:flutter/material.dart';

/// Renders [assetPath] if it exists in the asset bundle; otherwise renders
/// [fallback]. Lets screens reference an asset slot (e.g. from
/// `generated/assets.dart`) before the real image file has been added to
/// the project, without crashing or showing Flutter's red asset error box.
class AssetOrFallback extends StatelessWidget {
  const AssetOrFallback({
    super.key,
    required this.assetPath,
    required this.fallback,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
  });

  final String? assetPath;
  final Widget fallback;
  final BoxFit fit;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final path = assetPath;
    if (path == null || path.isEmpty) return fallback;

    return Image.asset(
      path,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => fallback,
    );
  }
}
