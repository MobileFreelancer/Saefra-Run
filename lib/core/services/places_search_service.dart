import 'dart:convert';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:saefra_run/core/config/api_config.dart';
import 'package:saefra_run/core/models/place_prediction_model.dart';

class PlacesSearchService {
  static const String _autocompleteUrl =
      'https://maps.googleapis.com/maps/api/place/autocomplete/json';

  static const String _detailsUrl =
      'https://maps.googleapis.com/maps/api/place/details/json';

  String get _apiKey => ApiConfig.googlePlacesApiKey;

  Future<List<PlacePrediction>> search(
      String query, {
        double? latitude,
        double? longitude,
      }) async {
    final trimmed = query.trim();

    if (trimmed.length < 2) {
      return [];
    }

    final Map<String, String> queryParameters = {
      'input': trimmed,
      'key': _apiKey,
    };

    if (latitude != null && longitude != null) {
      queryParameters['location'] = '$latitude,$longitude';
      queryParameters['radius'] = '50000';
    }

    final uri = Uri.parse(
      _autocompleteUrl,
    ).replace(queryParameters: queryParameters);

    log("Request URL: $uri");

    try {
      final response = await http.get(uri);

      debugPrint("HTTP Status Code: ${response.statusCode}");
      debugPrint("Response Body:");
      debugPrint(response.body);

      if (response.statusCode != 200) {
        return [];
      }

      final Map<String, dynamic> data = jsonDecode(response.body);

      final String status = data["status"] ?? "";

      if (status == "REQUEST_DENIED") {
        debugPrint("=====================================");
        debugPrint("GOOGLE REQUEST DENIED");
        debugPrint(data["error_message"]);
        debugPrint("=====================================");
        return [];
      }

      if (status == "ZERO_RESULTS") {
        return [];
      }

      if (status != "OK") {
        debugPrint("Places Status: $status");
        return [];
      }

      final List predictions = data["predictions"] ?? [];

      return predictions
          .map(
            (e) => PlacePrediction.fromGoogleJson(
          Map<String, dynamic>.from(e),
        ),
      )
          .toList();
    } catch (e, s) {
      debugPrint("Search Exception: $e");
      debugPrint(s.toString());
      return [];
    }
  }

  Future<LatLng?> resolvePlace(PlacePrediction prediction) async {
    if (prediction.placeId.isEmpty) {
      return null;
    }

    final uri = Uri.parse(
      _detailsUrl,
    ).replace(queryParameters: {
      "place_id": prediction.placeId,
      "fields": "geometry",
      "key": _apiKey,
    });

    log("Details URL: $uri");

    try {
      final response = await http.get(uri);

      debugPrint("Details Status Code: ${response.statusCode}");
      debugPrint("Details Response:");
      debugPrint(response.body);

      if (response.statusCode != 200) {
        return null;
      }

      final Map<String, dynamic> data = jsonDecode(response.body);

      if (data["status"] != "OK") {
        debugPrint("Details Status: ${data["status"]}");
        debugPrint("Error: ${data["error_message"]}");
        return null;
      }

      final location = data["result"]["geometry"]["location"];

      return LatLng(
        (location["lat"] as num).toDouble(),
        (location["lng"] as num).toDouble(),
      );
    } catch (e, s) {
      debugPrint("Resolve Exception: $e");
      debugPrint(s.toString());
      return null;
    }
  }
}