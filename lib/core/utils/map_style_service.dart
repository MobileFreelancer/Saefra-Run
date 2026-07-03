import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

enum MapTheme {
  light,
  dark,
  park,
}

class MapStyleService {
  static Future<void> applyStyle({
    required GoogleMapController controller,
    required MapTheme theme,
  }) async {
    String style = "";

    switch (theme) {
      case MapTheme.light:
        style = await rootBundle.loadString(
          'assets/map_style/light.json',
        );
        break;

      case MapTheme.dark:
        style = await rootBundle.loadString(
          'assets/map_style/dark.json',
        );
        break;

      case MapTheme.park:
        style = await rootBundle.loadString(
          'assets/map_style/park.json',
        );
        break;
    }

    controller.setMapStyle(style);
  }
}