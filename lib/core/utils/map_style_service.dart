import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

enum MapTheme {
  light,
  dark,
  park,
}

class MapStyleService {
  static final Map<MapTheme, String> _styleCache = {};

  static Future<void> applyStyle({
    required GoogleMapController controller,
    required MapTheme theme,
  }) async {
    final cached = _styleCache[theme];
    if (cached != null) {
      await controller.setMapStyle(cached);
      return;
    }

    final assetPath = switch (theme) {
      MapTheme.light => 'assets/map_style/light.json',
      MapTheme.dark => 'assets/map_style/dark.json',
      MapTheme.park => 'assets/map_style/park.json',
    };

    final style = await rootBundle.loadString(assetPath);
    _styleCache[theme] = style;
    await controller.setMapStyle(style);
  }
}