class CommunityRouteModel {
  final String id;
  final String name;
  final String location;
  final double distanceKm;
  final int durationMinutes;
  final double rating;
  final int reviewCount;
  final int likeCount;
  final int commentCount;
  final String? imageAsset;
  final String? difficultyTag;
  final List<String> tags;
  final double elevationGainM;
  final String? description;
  final List<String> runnerAvatars;

  const CommunityRouteModel({
    required this.id,
    required this.name,
    required this.location,
    this.distanceKm = 0,
    this.durationMinutes = 0,
    this.rating = 0,
    this.reviewCount = 0,
    this.likeCount = 0,
    this.commentCount = 0,
    this.imageAsset,
    this.difficultyTag,
    this.tags = const [],
    this.elevationGainM = 0,
    this.description,
    this.runnerAvatars = const [],
  });

  factory CommunityRouteModel.fromJson(Map<String, dynamic> json) {
    return CommunityRouteModel(
      id: '${json['id'] ?? json['route_id'] ?? ''}',
      name: json['name'] as String? ?? json['route_name'] as String? ?? 'Route',
      location: json['location'] as String? ?? '',
      distanceKm: _toDouble(json['distance_km'] ?? json['distance']),
      durationMinutes: _toInt(json['duration'] ?? json['estimated_duration']),
      rating: _toDouble(json['rating'] ?? json['community_rating']),
      reviewCount: _toInt(json['review_count'] ?? json['reviews_count']),
      likeCount: _toInt(json['like_count'] ?? json['likes']),
      commentCount: _toInt(json['comment_count'] ?? json['comments']),
      imageAsset: json['image'] as String? ?? json['route_image'] as String?,
      difficultyTag: json['difficulty'] as String? ?? json['difficulty_tag'] as String?,
      tags: (json['tags'] as List<dynamic>?)
              ?.map((e) => '$e')
              .toList() ??
          const [],
      elevationGainM: _toDouble(json['elevation_gain'] ?? json['elevation_gain_m']),
      description: json['description'] as String? ?? json['about'] as String?,
      runnerAvatars: (json['runner_avatars'] as List<dynamic>?)
              ?.map((e) => '$e')
              .toList() ??
          const [],
    );
  }

  static double _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
  }

  static int _toInt(dynamic v) {
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }
}
