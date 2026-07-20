import 'package:intl/intl.dart';

class AppNotificationModel {
  const AppNotificationModel({
    required this.id,
    required this.title,
    required this.message,
    this.category = '',
    this.notificationType = '',
    this.payload,
    this.isRead = false,
    this.readAt,
    this.createdAt = '',
    this.updatedAt = '',
  });

  final String id;
  final String title;
  final String message;
  final String category;
  final String notificationType;
  final Map<String, dynamic>? payload;
  final bool isRead;
  final String? readAt;
  final String createdAt;
  final String updatedAt;

  /// Backward-compatible alias used by inbox UI.
  String get userName => title;

  String get timestamp => _formatTimestamp(createdAt);

  AppNotificationModel copyWith({bool? isRead, String? readAt}) {
    return AppNotificationModel(
      id: id,
      title: title,
      message: message,
      category: category,
      notificationType: notificationType,
      payload: payload,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  factory AppNotificationModel.fromJson(Map<String, dynamic> json) {
    final payloadRaw = json['payload'];
    Map<String, dynamic>? payload;
    if (payloadRaw is Map) {
      payload = Map<String, dynamic>.from(payloadRaw);
    }

    return AppNotificationModel(
      id: '${json['id'] ?? ''}',
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      category: json['category'] as String? ?? '',
      notificationType: json['notification_type'] as String? ?? '',
      payload: payload,
      isRead: json['is_read'] == true || json['is_read'] == 1,
      readAt: json['read_at'] as String?,
      createdAt: json['created_at'] as String? ?? '',
      updatedAt: json['updated_at'] as String? ?? '',
    );
  }

  static String _formatTimestamp(String raw) {
    if (raw.trim().isEmpty) return '';
    final parsed = DateTime.tryParse(raw.replaceFirst(' ', 'T'));
    if (parsed == null) return raw;

    final now = DateTime.now();
    final diff = now.difference(parsed.toLocal());
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d, yyyy').format(parsed.toLocal());
  }
}

class NotificationListResult {
  const NotificationListResult({
    required this.notifications,
    required this.currentPage,
    required this.hasMore,
  });

  final List<AppNotificationModel> notifications;
  final int currentPage;
  final bool hasMore;
}
