import 'package:flutter/foundation.dart';

/// Resolves a displayable city/state for Activity items from API payload fields.
///
/// Prefer run-specific city/state (or reverse-geocodeable coordinates) over a
/// generic `location` string, which may be a stale route catalog default.
class ActivityLocationResolver {
  ActivityLocationResolver._();

  static String? resolveDisplayLocation(Map<String, dynamic> json) {
    final city = _string(
      json['city'] ??
          json['run_city'] ??
          json['locality'] ??
          json['town'] ??
          json['municipality'],
    );
    final state = _string(
      json['state'] ??
          json['run_state'] ??
          json['region'] ??
          json['state_code'] ??
          json['admin_area'] ??
          json['administrative_area'],
    );

    if (city != null && state != null) {
      final formatted = _formatCityState(city, state);
      debugPrint(
        '[ActivityLocation] Using city/state fields → $formatted '
        '(raw location=${json['location']})',
      );
      return formatted;
    }
    if (city != null) {
      debugPrint('[ActivityLocation] Using city field → $city');
      return city;
    }

    // When coordinates exist, do not trust a generic `location` string — it may
    // be a stale route-catalog default. Reverse-geocode instead.
    final coords = parseCoordinates(json);
    final street = _string(json['street'] ?? json['route_street'] ?? json['road']);
    if (coords != null) {
      debugPrint(
        '[ActivityLocation] Has coordinates '
        '(${coords.$1}, ${coords.$2}); deferring to reverse-geocode. '
        'street=$street raw location=${json['location']}',
      );
      return null;
    }

    final preferred = _string(
      json['city_state'] ??
          json['run_location'] ??
          json['display_location'] ??
          json['place_name'] ??
          json['place'],
    );
    if (preferred != null) {
      final fromPreferred = _extractCityState(preferred) ?? preferred;
      debugPrint(
        '[ActivityLocation] Using preferred location field → $fromPreferred',
      );
      return fromPreferred;
    }

    final address = _string(
      json['address'] ??
          json['formatted_address'] ??
          json['full_address'] ??
          json['run_address'],
    );
    if (address != null) {
      final fromAddress = _extractCityState(address);
      if (fromAddress != null) {
        debugPrint(
          '[ActivityLocation] Parsed city/state from address → $fromAddress '
          '(street=$street)',
        );
        return fromAddress;
      }
    }

    final location = _string(json['location']);
    if (street != null && location != null) {
      // Street for the run is known but city/state coords are missing. Avoid
      // showing a catalog `location` that may not match the completed run.
      debugPrint(
        '[ActivityLocation] Skipping potentially stale location="$location" '
        'because street="$street" is present without city/state/coords',
      );
      return null;
    }

    if (location != null) {
      final extracted = _extractCityState(location);
      debugPrint(
        '[ActivityLocation] Falling back to location field → '
        '${extracted ?? location}',
      );
      return extracted ?? location;
    }

    debugPrint('[ActivityLocation] No location fields found in activity payload');
    return null;
  }

  /// Returns `(latitude, longitude)` when present on the activity payload.
  static (double, double)? parseCoordinates(Map<String, dynamic> json) {
    final lat = _toDouble(
      json['latitude'] ??
          json['lat'] ??
          json['run_latitude'] ??
          json['start_latitude'] ??
          json['end_latitude'] ??
          json['finish_latitude'],
    );
    final lng = _toDouble(
      json['longitude'] ??
          json['lng'] ??
          json['lon'] ??
          json['run_longitude'] ??
          json['start_longitude'] ??
          json['end_longitude'] ??
          json['finish_longitude'],
    );
    if (lat != null && lng != null) return (lat, lng);

    final nested = json['coordinates'] ?? json['geo'] ?? json['position'];
    if (nested is Map) {
      final nestedLat = _toDouble(
        nested['latitude'] ?? nested['lat'],
      );
      final nestedLng = _toDouble(
        nested['longitude'] ?? nested['lng'] ?? nested['lon'],
      );
      if (nestedLat != null && nestedLng != null) {
        return (nestedLat, nestedLng);
      }
    }

    return null;
  }

  static String formatCityState(String city, String state) =>
      _formatCityState(city, state);

  static String? extractCityState(String value) => _extractCityState(value);

  static String _formatCityState(String city, String state) {
    final cleanedCity = city.trim();
    final cleanedState = state.trim();
    if (cleanedCity.isEmpty) return cleanedState;
    if (cleanedState.isEmpty) return cleanedCity;
    return '$cleanedCity, $cleanedState';
  }

  /// Extracts `City, ST` from strings like `S Main Street, Haverhill, MA 01830`.
  static String? _extractCityState(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;

    final usMatch = RegExp(
      r'([^,]+),\s*([A-Za-z]{2})(?:\s+\d{5}(?:-\d{4})?)?\s*$',
    ).firstMatch(trimmed);
    if (usMatch != null) {
      final city = usMatch.group(1)?.trim();
      final state = usMatch.group(2)?.trim().toUpperCase();
      if (city != null &&
          city.isNotEmpty &&
          state != null &&
          state.length == 2) {
        return _formatCityState(city, state);
      }
    }

    // Already "City, StateName" without postal code.
    final parts = trimmed.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty);
    final list = parts.toList();
    if (list.length >= 2) {
      final maybeCity = list[list.length - 2];
      final maybeState = list.last.split(RegExp(r'\s+')).first;
      if (maybeCity.isNotEmpty && maybeState.isNotEmpty) {
        return _formatCityState(maybeCity, maybeState);
      }
    }

    return null;
  }

  static String? _string(dynamic value) {
    if (value == null) return null;
    final text = '$value'.trim();
    return text.isEmpty ? null : text;
  }

  static double? _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.trim());
    return null;
  }
}
