import 'package:flutter/foundation.dart';
import 'package:saefra_run/core/models/notification_model.dart';

class NotificationInboxService extends ChangeNotifier {
  List<AppNotificationModel> _items = [];

  List<AppNotificationModel> get items => _items;
  bool get isEmpty => _items.isEmpty;

  int get unreadCount => _items.where((n) => !n.isRead).length;

  int get todayUnreadCount => unreadCount;

  void markAllRead() {
    _items = _items.map((n) => n.copyWith(isRead: true)).toList();
    notifyListeners();
  }

  void clearAll() {
    _items = [];
    notifyListeners();
  }

  void markRead(String id) {
    _items = _items
        .map((n) => n.id == id ? n.copyWith(isRead: true) : n)
        .toList();
    notifyListeners();
  }
}
