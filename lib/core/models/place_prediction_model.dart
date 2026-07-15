class PlacePrediction {
  const PlacePrediction({
    required this.description,
    required this.placeId,
    this.lat,
    this.lng,
  });

  final String description;
  final String placeId;
  final double? lat;
  final double? lng;

  factory PlacePrediction.fromGoogleJson(Map<String, dynamic> json) {
    return PlacePrediction(
      description: json['description'] as String? ?? 'Unknown location',
      placeId: json['place_id'] as String? ?? '',
    );
  }

  factory PlacePrediction.fromMock(Map<String, dynamic> json) {
    return PlacePrediction(
      description: json['description'] as String? ?? 'Unknown location',
      placeId: json['place_id'] as String? ?? '',
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
    );
  }
}
