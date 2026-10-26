import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'package:saefra_run/core/config/api_config.dart';
import 'package:saefra_run/core/utils/activity_location_resolver.dart';

/// Reverse-geocodes coordinates to a `City, ST` / address label.
class ReverseGeocodingService {
  ReverseGeocodingService({http.Client? client})
      : _client = client ?? http.Client();

  final http.Client _client;
  final Map<String, String> _cache = {};

  Future<String?> cityStateFromCoordinates({
    required double latitude,
    required double longitude,
  }) async {
    final resolved = await _lookup(latitude: latitude, longitude: longitude);
    return resolved?.cityState ?? resolved?.formattedAddress;
  }

  /// Address/location label for saving routes (`location` API field).
  Future<String?> addressFromCoordinates({
    required double latitude,
    required double longitude,
  }) async {
    final resolved = await _lookup(latitude: latitude, longitude: longitude);
    final label = resolved?.cityState ?? resolved?.formattedAddress;
    debugPrint(
      '[ReverseGeocode] address label → $label '
      '(lat=$latitude, lng=$longitude)',
    );
    return label;
  }

  Future<_GeocodeResult?> _lookup({
    required double latitude,
    required double longitude,
  }) async {
    final cacheKey =
        '${latitude.toStringAsFixed(4)},${longitude.toStringAsFixed(4)}';
    final cached = _cache[cacheKey];
    if (cached != null) {
      return _GeocodeResult(cityState: cached, formattedAddress: cached);
    }

    // 1) OpenStreetMap Nominatim — reliable HTTP reverse geocode (no Google key).
    final nominatim = await _lookupNominatim(
      latitude: latitude,
      longitude: longitude,
    );
    if (nominatim != null) {
      _cacheResult(cacheKey, nominatim);
      return nominatim;
    }

    // 2) Native platform geocoder.
    final native = await _lookupNative(
      latitude: latitude,
      longitude: longitude,
    );
    if (native != null) {
      _cacheResult(cacheKey, native);
      return native;
    }

    // 3) Google Geocoding API (needs Geocoding API enabled on the key).
    final google = await _lookupGoogle(
      latitude: latitude,
      longitude: longitude,
    );
    if (google != null) {
      _cacheResult(cacheKey, google);
      return google;
    }

    debugPrint(
      '[ReverseGeocode] All providers failed for $latitude,$longitude',
    );
    return null;
  }

  void _cacheResult(String key, _GeocodeResult result) {
    final cacheValue = result.cityState ?? result.formattedAddress;
    if (cacheValue != null) _cache[key] = cacheValue;
  }

  Future<_GeocodeResult?> _lookupNominatim({
    required double latitude,
    required double longitude,
  }) async {
    final uri = Uri.https(
      'nominatim.openstreetmap.org',
      '/reverse',
      {
        'format': 'jsonv2',
        'lat': '$latitude',
        'lon': '$longitude',
        'zoom': '10',
        'addressdetails': '1',
      },
    );

    try {
      debugPrint('[ReverseGeocode] Nominatim request $latitude,$longitude');
      final response = await _client
          .get(
            uri,
            headers: const {
              'User-Agent': 'SaefraRun/1.0 (saefra.run; route-location)',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) {
        debugPrint(
          '[ReverseGeocode] Nominatim HTTP ${response.statusCode}: '
          '${response.body}',
        );
        return null;
      }

      final body = jsonDecode(response.body);
      if (body is! Map) return null;
      final map = Map<String, dynamic>.from(body);
      final address = map['address'];
      if (address is! Map) {
        final display = map['display_name']?.toString().trim();
        if (display == null || display.isEmpty) return null;
        final extracted = ActivityLocationResolver.extractCityState(display);
        return _GeocodeResult(
          cityState: extracted,
          formattedAddress: display,
        );
      }

      final addressMap = Map<String, dynamic>.from(address);
      final city = _firstNonEmpty([
        addressMap['city'],
        addressMap['town'],
        addressMap['village'],
        addressMap['municipality'],
        addressMap['city_district'],
        addressMap['suburb'],
        addressMap['county'],
      ]);
      final stateRaw = _firstNonEmpty([
        addressMap['ISO3166-2-lvl4'],
        addressMap['state_code'],
        addressMap['state'],
      ]);
      final state = _normalizeState(stateRaw);
      final display = map['display_name']?.toString().trim();

      final cityState = (city != null && state != null)
          ? ActivityLocationResolver.formatCityState(city, state)
          : (city ??
              ActivityLocationResolver.extractCityState(display ?? '') ??
              state);

      debugPrint(
        '[ReverseGeocode] Nominatim → cityState=$cityState display=$display',
      );
      if (cityState == null && (display == null || display.isEmpty)) {
        return null;
      }
      return _GeocodeResult(
        cityState: cityState,
        formattedAddress: display,
      );
    } catch (e) {
      debugPrint('[ReverseGeocode] Nominatim failed: $e');
      return null;
    }
  }

  Future<_GeocodeResult?> _lookupNative({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude)
          .timeout(const Duration(seconds: 6));
      if (placemarks.isEmpty) {
        debugPrint('[ReverseGeocode] Native placemarks empty');
        return null;
      }

      final place = placemarks.first;
      final city = _nonEmpty(place.locality) ??
          _nonEmpty(place.subAdministrativeArea) ??
          _nonEmpty(place.subLocality);
      final state = _normalizeState(place.administrativeArea);
      final cityState = (city != null && state != null)
          ? ActivityLocationResolver.formatCityState(city, state)
          : (city ?? state);

      final parts = <String>[
        ?_nonEmpty(place.street),
        ?city,
        ?state,
        ?_nonEmpty(place.postalCode),
        ?_nonEmpty(place.country),
      ];
      final formatted = parts.isEmpty ? null : parts.join(', ');

      debugPrint(
        '[ReverseGeocode] Native → cityState=$cityState formatted=$formatted',
      );
      if (cityState == null && formatted == null) return null;
      return _GeocodeResult(cityState: cityState, formattedAddress: formatted);
    } catch (e) {
      debugPrint('[ReverseGeocode] Native failed: $e');
      return null;
    }
  }

  Future<_GeocodeResult?> _lookupGoogle({
    required double latitude,
    required double longitude,
  }) async {
    final keys = <String>{
      ApiConfig.googlePlacesApiKey,
      ApiConfig.googleMapsApiKey,
      ApiConfig.googleDirectionsApiKey,
      ApiConfig.googleRoutesApiKey,
    }.where((k) => k.trim().isNotEmpty).toList();

    for (final key in keys) {
      final uri = Uri.https(
        'maps.googleapis.com',
        '/maps/api/geocode/json',
        {
          'latlng': '$latitude,$longitude',
          'key': key,
        },
      );

      try {
        final response = await _client
            .get(uri)
            .timeout(const Duration(seconds: 8));
        if (response.statusCode != 200) continue;

        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final status = body['status']?.toString();
        if (status != 'OK') {
          debugPrint(
            '[ReverseGeocode] Google status=$status '
            'error=${body['error_message']}',
          );
          continue;
        }

        final results = body['results'] as List<dynamic>? ?? const [];
        final cityState = _resolveCityState(results);
        final formatted = _resolveFormattedAddress(results);
        if (cityState == null && formatted == null) continue;

        debugPrint(
          '[ReverseGeocode] Google → cityState=$cityState formatted=$formatted',
        );
        return _GeocodeResult(
          cityState: cityState,
          formattedAddress: formatted,
        );
      } catch (e) {
        debugPrint('[ReverseGeocode] Google failed: $e');
      }
    }
    return null;
  }

  String? _resolveFormattedAddress(List<dynamic> results) {
    for (final raw in results) {
      if (raw is! Map) continue;
      final formatted = raw['formatted_address']?.toString().trim();
      if (formatted != null && formatted.isNotEmpty) return formatted;
    }
    return null;
  }

  String? _resolveCityState(List<dynamic> results) {
    String? locality;
    String? adminArea;
    String? fromFormatted;

    for (final raw in results) {
      if (raw is! Map) continue;
      final map = Map<String, dynamic>.from(raw);
      final components = map['address_components'] as List<dynamic>? ?? const [];

      String? resultLocality;
      String? resultAdmin;

      for (final component in components) {
        if (component is! Map) continue;
        final types = (component['types'] as List<dynamic>? ?? const [])
            .map((e) => e.toString())
            .toList();
        final longName = component['long_name']?.toString();
        final shortName = component['short_name']?.toString();

        if (types.contains('locality') ||
            types.contains('postal_town') ||
            types.contains('sublocality') ||
            types.contains('administrative_area_level_3')) {
          resultLocality ??= longName ?? shortName;
        }
        if (types.contains('administrative_area_level_1')) {
          resultAdmin ??= shortName ?? longName;
        }
      }

      locality ??= resultLocality;
      adminArea ??= resultAdmin;

      final formatted = map['formatted_address']?.toString();
      if (fromFormatted == null && formatted != null) {
        fromFormatted = ActivityLocationResolver.extractCityState(formatted);
      }

      if (locality != null && adminArea != null) break;
    }

    if (locality != null && adminArea != null) {
      return ActivityLocationResolver.formatCityState(locality, adminArea);
    }
    return fromFormatted;
  }

  String? _firstNonEmpty(List<dynamic> values) {
    for (final value in values) {
      final text = _nonEmpty(value?.toString());
      if (text != null) return text;
    }
    return null;
  }

  String? _nonEmpty(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }

  String? _normalizeState(String? state) {
    final trimmed = _nonEmpty(state);
    if (trimmed == null) return null;

    // ISO3166-2-lvl4 like "US-CA"
    final iso = RegExp(r'^[A-Za-z]{2}-([A-Za-z]{2})$').firstMatch(trimmed);
    if (iso != null) return iso.group(1)!.toUpperCase();

    if (trimmed.length == 2) return trimmed.toUpperCase();

    const states = <String, String>{
      'alabama': 'AL',
      'alaska': 'AK',
      'arizona': 'AZ',
      'arkansas': 'AR',
      'california': 'CA',
      'colorado': 'CO',
      'connecticut': 'CT',
      'delaware': 'DE',
      'florida': 'FL',
      'georgia': 'GA',
      'hawaii': 'HI',
      'idaho': 'ID',
      'illinois': 'IL',
      'indiana': 'IN',
      'iowa': 'IA',
      'kansas': 'KS',
      'kentucky': 'KY',
      'louisiana': 'LA',
      'maine': 'ME',
      'maryland': 'MD',
      'massachusetts': 'MA',
      'michigan': 'MI',
      'minnesota': 'MN',
      'mississippi': 'MS',
      'missouri': 'MO',
      'montana': 'MT',
      'nebraska': 'NE',
      'nevada': 'NV',
      'new hampshire': 'NH',
      'new jersey': 'NJ',
      'new mexico': 'NM',
      'new york': 'NY',
      'north carolina': 'NC',
      'north dakota': 'ND',
      'ohio': 'OH',
      'oklahoma': 'OK',
      'oregon': 'OR',
      'pennsylvania': 'PA',
      'rhode island': 'RI',
      'south carolina': 'SC',
      'south dakota': 'SD',
      'tennessee': 'TN',
      'texas': 'TX',
      'utah': 'UT',
      'vermont': 'VT',
      'virginia': 'VA',
      'washington': 'WA',
      'west virginia': 'WV',
      'wisconsin': 'WI',
      'wyoming': 'WY',
      'district of columbia': 'DC',
    };
    return states[trimmed.toLowerCase()] ?? trimmed;
  }
}

class _GeocodeResult {
  const _GeocodeResult({this.cityState, this.formattedAddress});

  final String? cityState;
  final String? formattedAddress;
}
