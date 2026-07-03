class ReviewModel {
  final String id;
  final String userName;
  final String? avatarUrl;
  final double rating;
  final String comment;
  final String? timeAgo;

  const ReviewModel({
    required this.id,
    required this.userName,
    this.avatarUrl,
    required this.rating,
    required this.comment,
    this.timeAgo,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: '${json['id'] ?? ''}',
      userName: json['user_name'] as String? ?? json['username'] as String? ?? 'User',
      avatarUrl: json['avatar'] as String? ?? json['avatar_url'] as String?,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      comment: json['comment'] as String? ?? json['review'] as String? ?? '',
      timeAgo: json['time_ago'] as String? ?? json['created_at'] as String?,
    );
  }
}
