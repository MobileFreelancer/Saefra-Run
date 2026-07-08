class AppNotificationModel {
  const AppNotificationModel({
    required this.id,
    required this.userName,
    required this.message,
    required this.timestamp,
    this.avatarAsset,
    this.isRead = false,
  });

  final String id;
  final String userName;
  final String message;
  final String timestamp;
  final String? avatarAsset;
  final bool isRead;

  AppNotificationModel copyWith({bool? isRead}) {
    return AppNotificationModel(
      id: id,
      userName: userName,
      message: message,
      timestamp: timestamp,
      avatarAsset: avatarAsset,
      isRead: isRead ?? this.isRead,
    );
  }
}
