import 'package:flutter/foundation.dart';
import 'package:saefra_run/core/models/notification_model.dart';
import 'package:saefra_run/core/services/api_service.dart';

class NotificationInboxService extends ChangeNotifier {
  NotificationInboxService();

  final ApiService _api = ApiService();

  List<AppNotificationModel> _items = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  bool _hasLoaded = false;
  int _currentPage = 1;
  String? _error;
  String? _category;

  static const int _perPage = 20;

  List<AppNotificationModel> get items => _items;
  bool get isEmpty => _items.isEmpty;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  String? get error => _error;

  int get unreadCount => _items.where((n) => !n.isRead).length;
  int get todayUnreadCount => unreadCount;

  void prependFromPush({
    required String title,
    required String body,
    Map<String, dynamic> data = const {},
  }) {
    final item = AppNotificationModel(
      id: 'push-${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      message: body,
      category: data['category']?.toString() ?? 'Push',
      notificationType: data['notification_type']?.toString() ?? 'push',
      isRead: false,
      createdAt: DateTime.now().toIso8601String(),
    );
    _items = [item, ..._items];
    notifyListeners();
  }

  Future<void> loadIfNeeded() async {
    if (_hasLoaded || _isLoading) return;
    _hasLoaded = true;
    await load(refresh: true);
  }

  Future<void> load({String? category, bool refresh = false}) async {
    if (_isLoading) return;

    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
    }

    _category = category;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _api.getNotifications(
        category: _category,
        page: _currentPage,
        perPage: _perPage,
      );

      if (refresh) {
        final localPush =
            _items.where((n) => n.id.startsWith('push-')).toList();
        _items = [...localPush, ...result.notifications];
      } else {
        _items = [..._items, ...result.notifications];
      }
      _hasMore = result.hasMore;
      _currentPage = result.currentPage;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore || _isLoading) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final nextPage = _currentPage + 1;
      final result = await _api.getNotifications(
        category: _category,
        page: nextPage,
        perPage: _perPage,
      );

      _items = [..._items, ...result.notifications];
      _hasMore = result.hasMore;
      _currentPage = nextPage;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> markRead(String id) async {
    final index = _items.indexWhere((n) => n.id == id);
    if (index == -1) return;

    final previous = _items[index];
    if (previous.isRead) return;

    _items = _items
        .map((n) => n.id == id ? n.copyWith(isRead: true) : n)
        .toList();
    notifyListeners();

    try {
      final updated = await _api.markNotificationRead(id);
      _items = _items
          .map((n) => n.id == id ? updated : n)
          .toList();
      notifyListeners();
    } catch (e) {
      _items = _items
          .map((n) => n.id == id ? previous : n)
          .toList();
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteNotification(String id) async {
    final previous = List<AppNotificationModel>.from(_items);
    _items = _items.where((n) => n.id != id).toList();
    notifyListeners();

    try {
      await _api.deleteNotification(id);
    } catch (e) {
      _items = previous;
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<bool> clearAll() async {
    final previous = List<AppNotificationModel>.from(_items);
    _items = [];
    notifyListeners();

    try {
      await _api.clearAllNotifications();
      return true;
    } catch (e) {
      _items = previous;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
