class ReviewModel {
  final String id;
  final String userName;
  final String? avatarUrl;
  final double rating;
  final String comment;
  final String? timeAgo;
  final int likeCount;
  final List<String> photos;

  const ReviewModel({
    required this.id,
    required this.userName,
    this.avatarUrl,
    required this.rating,
    required this.comment,
    this.timeAgo,
    this.likeCount = 0,
    this.photos = const [],
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    final user = json['user'];
    final userMap = user is Map ? Map<String, dynamic>.from(user) : null;

    return ReviewModel(
      id: '${json['id'] ?? json['review_id'] ?? ''}',
      userName: userMap?['name'] as String? ??
          json['user_name'] as String? ??
          json['username'] as String? ??
          json['name'] as String? ??
          'User',
      avatarUrl: _nullableString(
        userMap?['profile_image'] ??
            userMap?['avatar'] ??
            json['avatar'] ??
            json['avatar_url'] ??
            json['profile_image'] ,
      ),
      rating: _toDouble(
        json['rating'] ?? json['overall_rating'] ?? json['stars'],
      ),
      comment: json['comment'] as String? ??
          json['review'] as String? ??
          json['message'] as String? ??
          '',
      timeAgo: json['time_ago'] as String? ??
          json['date'] as String? ??
          json['created_at'] as String?,
      likeCount: _toInt(json['like_count'] ?? json['likes']),
      photos: _parsePhotos(json['photos']),
    );
  }

  static List<String> _parsePhotos(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .map((item) {
          if (item is String) return item.trim();
          if (item is Map) {
            final url = item['url'] ?? item['image'] ?? item['photo'];
            return url == null ? '' : '$url'.trim();
          }
          return '';
        })
        .where((url) => url.isNotEmpty)
        .toList();
  }

  static String? _nullableString(dynamic value) {
    if (value == null) return null;
    final text = '$value'.trim();
    return text.isEmpty ? null : text;
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  static int _toInt(dynamic value) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
