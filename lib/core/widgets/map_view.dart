import 'package:flutter/material.dart';
import 'package:saefra_run/core/constants/app_colors.dart';

/// A single, isolated seam for the app's map.
///
/// TODAY: renders a tasteful static placeholder (grid + route line +
/// location dot) so the dashboard looks finished with zero map SDK wired
/// up — no API key, no package, no setup required yet.
///
/// LATER: once you add `google_maps_flutter` (or Mapbox / flutter_map),
/// replace just the `build()` body below with the real map widget. Every
/// call site (`MapView(...)`) and all of its parameters stay the same, so
/// nothing else in the app needs to change — just this one file.
///
/// Example of what the swap looks like later:
/// ```dart
/// return GoogleMap(
///   initialCameraPosition: CameraPosition(target: center, zoom: zoom),
///   markers: markers,
///   polylines: polylines,
///   myLocationEnabled: showUserLocation,
///   ...
/// );
/// ```
class MapView extends StatelessWidget {
  const MapView({
    super.key,
    this.center,
    this.zoom = 15,
    this.showUserLocation = true,
    this.routePoints = const [],
    this.markers = const [],
    this.onMapTap,
  });

  /// Map center, e.g. LatLng-style coordinates. Kept as a simple record so
  /// this file has no dependency on any map package yet.
  final ({double lat, double lng})? center;

  final double zoom;
  final bool showUserLocation;

  /// Placeholder route polyline points — wire real LatLng lists in later.
  final List<({double lat, double lng})> routePoints;

  /// Placeholder markers — wire real Marker objects in later.
  final List<({double lat, double lng, String? label})> markers;

  final VoidCallback? onMapTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onMapTap,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: const Color(0xFF15171A),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(painter: _MapGridPainter()),
            if (showUserLocation) const Center(child: _PulsingLocationDot()),
          ],
        ),
      ),
    );
  }
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 1;

    const spacing = 28.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // A couple of stylized "road" lines so the placeholder doesn't look
    // like a bare grid.
    final roadPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.10)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(size.width * 0.1, size.height * 0.75),
      Offset(size.width * 0.9, size.height * 0.2),
      roadPaint,
    );

    final routePaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.55)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(size.width * 0.15, size.height * 0.15),
      Offset(size.width * 0.85, size.height * 0.85),
      routePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PulsingLocationDot extends StatefulWidget {
  const _PulsingLocationDot();

  @override
  State<_PulsingLocationDot> createState() => _PulsingLocationDotState();
}

class _PulsingLocationDotState extends State<_PulsingLocationDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final scale = 1 + (_controller.value * 0.8);
        final opacity = (1 - _controller.value).clamp(0.0, 1.0);
        return SizedBox(
          width: 60,
          height: 60,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Transform.scale(
                scale: scale,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF3B82F6).withValues(alpha: opacity * 0.4),
                  ),
                ),
              ),
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF3B82F6),
                  border: Border.all(color: AppColors.white, width: 2.5),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
