import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:saefra_run/core/config/api_config.dart';
import 'package:saefra_run/core/models/place_prediction_model.dart';

class PlacesSearchService {
  static const _autocompleteUrl =
      'https://maps.googleapis.com/maps/api/place/autocomplete/json';
  static const _detailsUrl =
      'https://maps.googleapis.com/maps/api/place/details/json';

  String get _apiKey => ApiConfig.googlePlacesApiKey;

  bool get _hasApiKey =>
      _apiKey.isNotEmpty && _apiKey != 'YOUR_GOOGLE_MAPS_API_KEY_HERE';

  Future<List<PlacePrediction>> search(
    String query, {
    double? latitude,
    double? longitude,
  }) async {
    final trimmed = query.trim();
    if (trimmed.length < 2) return [];

    if (!_hasApiKey) {
      debugPrint('PlacesSearchService: no API key configured');
      return [];
    }

    final locationBias = latitude != null && longitude != null
        ? '&location=$latitude,$longitude&radius=50000'
        : '';

    final url =
        '$_autocompleteUrl?input=${Uri.encodeComponent(trimmed)}$locationBias&key=$_apiKey';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        debugPrint('Places autocomplete HTTP ${response.statusCode}');
        return [];
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
      final status = data['status'] as String? ?? 'UNKNOWN';

      if (status != 'OK' && status != 'ZERO_RESULTS') {
        debugPrint(
          'Places autocomplete status: $status — ${data['error_message'] ?? ''}',
        );
        return [];
      }

      final predictions = data['predictions'] as List<dynamic>? ?? [];
      return predictions
          .map(
            (item) => PlacePrediction.fromGoogleJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .where((place) => place.placeId.isNotEmpty)
          .toList();
    } catch (e) {
      debugPrint('PlacesSearchService.search failed: $e');
      return [];
    }
  }

  Future<LatLng?> resolvePlace(PlacePrediction prediction) async {
    if (prediction.lat != null && prediction.lng != null) {
      return LatLng(prediction.lat!, prediction.lng!);
    }

    if (!_hasApiKey || prediction.placeId.isEmpty) return null;

    final url =
        '$_detailsUrl?place_id=${Uri.encodeComponent(prediction.placeId)}&fields=geometry&key=$_apiKey';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) return null;

      final data = json.decode(response.body) as Map<String, dynamic>;
      if (data['status'] != 'OK') return null;

      final location =
          (data['result'] as Map<String, dynamic>?)?['geometry']
              as Map<String, dynamic>?;
      final latLng = location?['location'] as Map<String, dynamic>?;
      if (latLng == null) return null;

      return LatLng(
        (latLng['lat'] as num).toDouble(),
        (latLng['lng'] as num).toDouble(),
      );
    } catch (e) {
      debugPrint('PlacesSearchService.resolvePlace failed: $e');
      return null;
    }
  }
}
