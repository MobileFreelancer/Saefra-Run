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

  factory PlacePrediction.fromPlacesApi(Map<String, dynamic> json) {
    final text = json['text'];
    final description = text is Map ? text['text'] as String? : null;
    return PlacePrediction(
      description: (description != null && description.isNotEmpty)
          ? description
          : 'Unknown location',
      placeId: json['placeId'] as String? ?? '',
    );
  }
}
