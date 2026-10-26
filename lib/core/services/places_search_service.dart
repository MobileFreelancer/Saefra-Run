import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:saefra_run/core/config/api_config.dart';
import 'package:saefra_run/core/models/place_prediction_model.dart';

class PlacesSearchService {
  static const String _autocompleteUrl =
      'https://places.googleapis.com/v1/places:autocomplete';

  static const String _detailsUrl = 'https://places.googleapis.com/v1/places';

  String get _apiKey => ApiConfig.googlePlacesApiKey;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'X-Goog-Api-Key': _apiKey,
      };

  Future<List<PlacePrediction>> search(
    String query, {
    double? latitude,
    double? longitude,
  }) async {
    final trimmed = query.trim();

    if (trimmed.length < 2 || _apiKey.isEmpty) {
      return [];
    }

    final Map<String, dynamic> body = {'input': trimmed};

    if (latitude != null && longitude != null) {
      body['locationBias'] = {
        'circle': {
          'center': {
            'latitude': latitude,
            'longitude': longitude,
          },
          'radius': 50000.0,
        },
      };
    }

    try {
      final response = await http.post(
        Uri.parse(_autocompleteUrl),
        headers: _headers,
        body: jsonEncode(body),
      );

      debugPrint('Places autocomplete status: ${response.statusCode}');

      if (response.statusCode != 200) {
        debugPrint('Places autocomplete error: ${response.body}');
        return [];
      }

      final Map<String, dynamic> data =
          jsonDecode(response.body) as Map<String, dynamic>;
      final List suggestions = data['suggestions'] as List? ?? [];

      return suggestions
          .map((item) {
            final map = Map<String, dynamic>.from(item as Map);
            final prediction = map['placePrediction'];
            if (prediction is! Map) return null;
            return PlacePrediction.fromPlacesApi(
              Map<String, dynamic>.from(prediction),
            );
          })
          .whereType<PlacePrediction>()
          .where((place) => place.placeId.isNotEmpty)
          .toList();
    } catch (e, s) {
      debugPrint('Search Exception: $e');
      debugPrint(s.toString());
      return [];
    }
  }

  Future<LatLng?> resolvePlace(PlacePrediction prediction) async {
    if (prediction.placeId.isEmpty || _apiKey.isEmpty) {
      return null;
    }

    final uri = Uri.parse('$_detailsUrl/${prediction.placeId}');

    try {
      final response = await http.get(
        uri,
        headers: {
          ..._headers,
          'X-Goog-FieldMask': 'location',
        },
      );

      debugPrint('Places details status: ${response.statusCode}');

      if (response.statusCode != 200) {
        debugPrint('Places details error: ${response.body}');
        return null;
      }

      final Map<String, dynamic> data =
          jsonDecode(response.body) as Map<String, dynamic>;
      final location = data['location'];
      if (location is! Map) return null;

      final lat = location['latitude'];
      final lng = location['longitude'];
      if (lat is! num || lng is! num) return null;

      return LatLng(lat.toDouble(), lng.toDouble());
    } catch (e, s) {
      debugPrint('Resolve Exception: $e');
      debugPrint(s.toString());
      return null;
    }
  }
}
