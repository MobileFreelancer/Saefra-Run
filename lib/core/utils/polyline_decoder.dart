import 'package:google_maps_flutter/google_maps_flutter.dart';

class PolylineDecoder {
  PolylineDecoder._();

  static List<LatLng> decode(String? encoded) {
    if (encoded == null || encoded.isEmpty) return [];

    final points = <LatLng>[];
    var index = 0;
    final len = encoded.length;
    var lat = 0;
    var lng = 0;

    while (index < len) {
      var shift = 0;
      var result = 0;
      int b;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      final dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      final dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1e5, lng / 1e5));
    }

    return points;
  }

  static List<LatLng> fromRouteJson(Map<String, dynamic> json) {
    for (final key in [
      'route_encoded_polyline',
      'encoded_polyline',
      'route_coordinates',
    ]) {
      final value = json[key];
      if (value is String && value.isNotEmpty) {
        final points = decode(value);
        if (points.length > 1) return points;
      }
    }

    final start = _pointFromJson(json, 'start');
    final end = _pointFromJson(json, 'end');
    if (start != null && end != null) {
      return [start, end];
    }

    return [];
  }

  static LatLng? _pointFromJson(Map<String, dynamic> json, String prefix) {
    final lat = _toDouble(json['${prefix}_latitude']);
    final lng = _toDouble(json['${prefix}_longitude']);
    if (lat == null || lng == null) return null;
    return LatLng(lat, lng);
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}
