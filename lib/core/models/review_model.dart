class ReviewModel {
  final String id;
  final String userName;
  final String? avatarUrl;
  final double rating;
  final String comment;
  final String? timeAgo;
  final int likeCount;

  const ReviewModel({
    required this.id,
    required this.userName,
    this.avatarUrl,
    required this.rating,
    required this.comment,
    this.timeAgo,
    this.likeCount = 0,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: '${json['id'] ?? json['review_id'] ?? ''}',
      userName: json['user_name'] as String? ??
          json['username'] as String? ??
          json['name'] as String? ??
          'User',
      avatarUrl: _nullableString(
        json['avatar'] ?? json['avatar_url'] ?? json['profile_image'],
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
    );
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
