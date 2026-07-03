import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../utils/map_style_service.dart';

void showMapStyleBottomSheet(
    BuildContext context,
    GoogleMapController controller,
    ) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(20),
      ),
    ),
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              const Text(
                "Select Map Style",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              ListTile(
                leading: const Icon(Icons.light_mode),
                title: const Text("Light"),
                onTap: () async {
                  await MapStyleService.applyStyle(
                    controller: controller,
                    theme: MapTheme.light,
                  );
                  Navigator.pop(context);
                },
              ),

              ListTile(
                leading: const Icon(Icons.dark_mode),
                title: const Text("Dark"),
                onTap: () async {
                  await MapStyleService.applyStyle(
                    controller: controller,
                    theme: MapTheme.dark,
                  );
                  Navigator.pop(context);
                },
              ),

              ListTile(
                leading: const Icon(Icons.park),
                title: const Text("Park"),
                onTap: () async {
                  await MapStyleService.applyStyle(
                    controller: controller,
                    theme: MapTheme.park,
                  );
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}