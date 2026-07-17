import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:saefra_run/core/constants/app_colors.dart';
import 'package:saefra_run/core/services/dashboard_services.dart';
import 'package:saefra_run/core/utils/location_route_utils.dart';
import 'package:saefra_run/core/utils/map_style_service.dart';

/// Reusable Google Map — draws route polylines without continuous camera fighting.
class AppRouteMap extends StatefulWidget {
  const AppRouteMap({
    super.key,
    this.height,
    this.borderRadius = 16,
    this.polylinePoints,
    this.origin,
    this.destination,
    this.showRoutePolyline = true,
    this.showLocationMarker = true,
    this.fallbackToDashboardPolyline = false,
    this.fitToContent = true,
    this.preferDestinationCamera = false,
    this.zoom = 14,
    this.useDashboardLocation = false,
  });

  final double? height;
  final double borderRadius;
  final List<LatLng>? polylinePoints;
  final LatLng? origin;
  final LatLng? destination;
  final bool showRoutePolyline;
  final bool showLocationMarker;
  final bool fallbackToDashboardPolyline;
  final bool fitToContent;
  final bool preferDestinationCamera;
  final double zoom;
  /// When false and [origin]/[polylinePoints] are provided, GPS stream updates
  /// from [DashboardServices] will not rebuild or re-fit this map.
  final bool useDashboardLocation;

  @override
  State<AppRouteMap> createState() => _AppRouteMapState();
}

class _AppRouteMapState extends State<AppRouteMap> {
  GoogleMapController? _controller;
  String? _lastFitKey;
  bool _userMovedCamera = false;
  bool _styleApplied = false;

  bool get _standalone =>
      !widget.useDashboardLocation &&
      (widget.origin != null ||
          widget.destination != null ||
          widget.polylinePoints != null);

  @override
  Widget build(BuildContext context) {
    if (_standalone) {
      return _wrapMap(
        _buildMap(
          origin: widget.origin,
          destination: widget.destination,
          polylinePoints: widget.polylinePoints ?? const [],
        ),
      );
    }

    return Selector<DashboardServices, _DashboardMapData>(
      selector: (_, services) => _DashboardMapData.from(
        services,
        includePolyline: widget.fallbackToDashboardPolyline,
      ),
      builder: (context, data, _) {
        final origin = widget.origin ??
            (data.latitude != null && data.longitude != null
                ? LatLng(data.latitude!, data.longitude!)
                : null);
        final destination = widget.destination ??
            (data.destinationLatitude != null &&
                    data.destinationLongitude != null
                ? LatLng(
                    data.destinationLatitude!,
                    data.destinationLongitude!,
                  )
                : null);
        final points = _resolvePoints(
          widget.polylinePoints,
          widget.fallbackToDashboardPolyline
              ? data.routePolylinePoints
              : const [],
        );

        return _wrapMap(
          _buildMap(
            origin: origin,
            destination: destination,
            polylinePoints: points,
          ),
        );
      },
    );
  }

  Widget _wrapMap(Widget map) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: widget.height != null
          ? SizedBox(
              height: widget.height,
              width: double.infinity,
              child: map,
            )
          : SizedBox.expand(child: map),
    );
  }

  Widget _buildMap({
    required LatLng? origin,
    required LatLng? destination,
    required List<LatLng> polylinePoints,
  }) {
    final target = origin ??
        destination ??
        (polylinePoints.isNotEmpty
            ? polylinePoints.first
            : const LatLng(21.1702, 72.8311));

    final useLocalCamera = !widget.preferDestinationCamera &&
        LocationRouteUtils.shouldUseLocalCamera(origin, destination);
    final showOriginMarker = origin != null &&
        (destination == null ||
            LocationRouteUtils.isPlausibleRoute(origin, destination));

    final markers = <Marker>{};
    if (showOriginMarker) {
      markers.add(
        Marker(
          markerId: const MarkerId('route_origin'),
          position: origin,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
          infoWindow: const InfoWindow(title: 'Start'),
        ),
      );
    }

    if (destination != null && !_nearLatLng(origin, destination)) {
      markers.add(
        Marker(
          markerId: const MarkerId('route_destination'),
          position: destination,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueRed,
          ),
          infoWindow: const InfoWindow(title: 'Destination'),
        ),
      );
    }

    final fitKey = _fitKey(markers, polylinePoints, useLocalCamera);
    _scheduleFitIfNeeded(
      fitKey: fitKey,
      markers: markers,
      points: polylinePoints,
      fallbackTarget: destination ?? target,
      useLocalCamera: useLocalCamera,
    );

    return GoogleMap(
      key: ValueKey('app_route_map_${widget.hashCode}'),
      initialCameraPosition: CameraPosition(target: target, zoom: widget.zoom),
      myLocationEnabled: false,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: true,
      zoomGesturesEnabled: true,
      scrollGesturesEnabled: true,
      rotateGesturesEnabled: true,
      tiltGesturesEnabled: true,
      compassEnabled: false,
      mapToolbarEnabled: false,
      markers: markers,
      polylines: widget.showRoutePolyline && polylinePoints.length > 1
          ? {
              Polyline(
                polylineId: const PolylineId('app_route_polyline'),
                points: polylinePoints,
                color: AppColors.primary,
                width: 5,
              ),
            }
          : {},
      onCameraMoveStarted: () {
        _userMovedCamera = true;
      },
      onMapCreated: (controller) async {
        _controller = controller;
        if (!_styleApplied) {
          _styleApplied = true;
          final theme = context.read<DashboardServices>().mapTheme;
          await MapStyleService.applyStyle(
            controller: controller,
            theme: theme,
          );
        }
        if (widget.fitToContent && !_userMovedCamera) {
          await _fitCamera(
            markers,
            polylinePoints,
            fallbackTarget: destination ?? target,
            useLocalCamera: useLocalCamera,
          );
        }
      },
    );
  }

  void _scheduleFitIfNeeded({
    required String fitKey,
    required Set<Marker> markers,
    required List<LatLng> points,
    required LatLng fallbackTarget,
    required bool useLocalCamera,
  }) {
    if (!widget.fitToContent || fitKey == _lastFitKey) return;
    _lastFitKey = fitKey;
    _userMovedCamera = false;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fitCamera(
        markers,
        points,
        fallbackTarget: fallbackTarget,
        useLocalCamera: useLocalCamera,
      );
    });
  }

  Future<void> _fitCamera(
    Set<Marker> markers,
    List<LatLng> points, {
    required LatLng fallbackTarget,
    required bool useLocalCamera,
  }) async {
    if (_userMovedCamera) return;

    final controller = _controller;
    if (controller == null) return;

    final allPoints = <LatLng>[
      if (useLocalCamera) ...markers.map((marker) => marker.position),
      ...points,
    ];

    if (!useLocalCamera) {
      final destinationMarker = markers.where(
        (marker) => marker.markerId.value == 'route_destination',
      );
      if (destinationMarker.isNotEmpty) {
        await controller.animateCamera(
          CameraUpdate.newLatLngZoom(
            destinationMarker.first.position,
            widget.zoom,
          ),
        );
        return;
      }
    }

    if (allPoints.isEmpty) {
      await controller.animateCamera(
        CameraUpdate.newLatLngZoom(fallbackTarget, widget.zoom),
      );
      return;
    }

    if (allPoints.length == 1) {
      await controller.animateCamera(
        CameraUpdate.newLatLngZoom(allPoints.first, widget.zoom),
      );
      return;
    }

    var minLat = allPoints.first.latitude;
    var maxLat = allPoints.first.latitude;
    var minLng = allPoints.first.longitude;
    var maxLng = allPoints.first.longitude;

    for (final point in allPoints) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    if ((maxLat - minLat).abs() < 1e-6 && (maxLng - minLng).abs() < 1e-6) {
      await controller.animateCamera(
        CameraUpdate.newLatLngZoom(allPoints.first, widget.zoom),
      );
      return;
    }

    try {
      await controller.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(minLat, minLng),
            northeast: LatLng(maxLat, maxLng),
          ),
          56,
        ),
      );
    } catch (_) {
      await controller.animateCamera(
        CameraUpdate.newLatLngZoom(allPoints.first, widget.zoom),
      );
    }
  }

  String _fitKey(
    Set<Marker> markers,
    List<LatLng> points,
    bool useLocalCamera,
  ) {
    final markerKey = markers
        .map(
          (marker) =>
              '${marker.markerId.value}:${_roundCoord(marker.position.latitude)},${_roundCoord(marker.position.longitude)}',
        )
        .join('|');
    final pointKey = points.isEmpty
        ? ''
        : '${_roundCoord(points.first.latitude)},${_roundCoord(points.first.longitude)}->'
            '${_roundCoord(points.last.latitude)},${_roundCoord(points.last.longitude)}(${points.length})';
    return '$markerKey#$pointKey#$useLocalCamera';
  }

  List<LatLng> _resolvePoints(
    List<LatLng>? explicitPoints,
    List<LatLng> dashboardPoints,
  ) {
    if (explicitPoints != null && explicitPoints.length > 1) {
      return explicitPoints;
    }
    if (dashboardPoints.length > 1) {
      return dashboardPoints;
    }
    return const [];
  }

  static double _roundCoord(double value) =>
      (value * 1000).roundToDouble() / 1000;

  static bool _nearLatLng(LatLng? a, LatLng? b, {double epsilon = 0.0005}) {
    if (a == null || b == null) return false;
    return (a.latitude - b.latitude).abs() < epsilon &&
        (a.longitude - b.longitude).abs() < epsilon;
  }
}

class _DashboardMapData {
  const _DashboardMapData({
    required this.latitude,
    required this.longitude,
    required this.destinationLatitude,
    required this.destinationLongitude,
    required this.routePolylinePoints,
  });

  final double? latitude;
  final double? longitude;
  final double? destinationLatitude;
  final double? destinationLongitude;
  final List<LatLng> routePolylinePoints;

  factory _DashboardMapData.from(
    DashboardServices services, {
    required bool includePolyline,
  }) {
    return _DashboardMapData(
      latitude: services.latitude,
      longitude: services.longitude,
      destinationLatitude: services.destinationPositionLatitude,
      destinationLongitude: services.destinationPositionLongitude,
      routePolylinePoints:
          includePolyline ? services.routePolylinePoints : const [],
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _DashboardMapData &&
        other.latitude == latitude &&
        other.longitude == longitude &&
        other.destinationLatitude == destinationLatitude &&
        other.destinationLongitude == destinationLongitude &&
        _polylineEqual(other.routePolylinePoints, routePolylinePoints);
  }

  @override
  int get hashCode => Object.hash(
        latitude,
        longitude,
        destinationLatitude,
        destinationLongitude,
        routePolylinePoints.length,
        routePolylinePoints.isEmpty
            ? 0
            : routePolylinePoints.first.latitude,
      );

  static bool _polylineEqual(List<LatLng> a, List<LatLng> b) {
    if (a.length != b.length) return false;
    if (a.isEmpty) return true;
    return a.first.latitude == b.first.latitude &&
        a.first.longitude == b.first.longitude &&
        a.last.latitude == b.last.latitude &&
        a.last.longitude == b.last.longitude;
  }
}
