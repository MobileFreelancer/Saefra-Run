import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:saefra_run/core/constants/app_colors.dart';
import 'package:saefra_run/core/models/notification_model.dart';
import 'package:saefra_run/core/services/notification_inbox_service.dart';
import 'package:saefra_run/core/widgets/app_page_header.dart';

class NotificationsInboxScreen extends StatefulWidget {
  const NotificationsInboxScreen({super.key});

  @override
  State<NotificationsInboxScreen> createState() =>
      _NotificationsInboxScreenState();
}

class _NotificationsInboxScreenState extends State<NotificationsInboxScreen> {
  final _scrollController = ScrollController();

  TextStyle _body(BuildContext context, {Color? color, FontWeight? weight}) {
    return Theme.of(context).textTheme.bodyMedium!.copyWith(
          color: color ?? AppColors.white,
          fontWeight: weight,
        );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationInboxService>().loadIfNeeded();
    });
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final inbox = context.read<NotificationInboxService>();
    if (!inbox.hasMore || inbox.isLoadingMore) return;

    final threshold = _scrollController.position.maxScrollExtent - 120;
    if (_scrollController.position.pixels >= threshold) {
      inbox.loadMore();
    }
  }

  Future<void> _clearAll(BuildContext context) async {
    final inbox = context.read<NotificationInboxService>();
    final ok = await inbox.clearAll();
    if (!context.mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(inbox.error ?? 'Failed to clear notifications.')),
      );
    }
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inbox = context.watch<NotificationInboxService>();
    final bodyStyle = _body(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppPageHeader(
              title: 'Notifications',
              trailing: inbox.isEmpty
                  ? null
                  : TextButton(
                      onPressed: inbox.isLoading ? null : () => _clearAll(context),
                      child: Text(
                        'Clear All',
                        style: bodyStyle.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
            ),
            Expanded(
              child: inbox.isLoading && inbox.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    )
                  : inbox.isEmpty
                      ? _EmptyNotifications(bodyStyle: bodyStyle)
                      : RefreshIndicator(
                          color: AppColors.primary,
                          onRefresh: () =>
                              inbox.load(refresh: true),
                          child: ListView(
                            controller: _scrollController,
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h),
                            children: [
                              if (inbox.unreadCount > 0)
                                Text(
                                  'You have ${inbox.unreadCount} new notification${inbox.unreadCount == 1 ? '' : 's'}',
                                  style: bodyStyle.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              if (inbox.unreadCount > 0) SizedBox(height: 16.h),
                              ...inbox.items.map(
                                (item) => _NotificationTile(
                                  item: item,
                                  bodyStyle: bodyStyle,
                                  onTap: () => inbox.markRead(item.id),
                                  onDelete: () =>
                                      inbox.deleteNotification(item.id),
                                ),
                              ),
                              if (inbox.isLoadingMore)
                                Padding(
                                  padding: EdgeInsets.symmetric(vertical: 16.h),
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyNotifications extends StatelessWidget {
  const _EmptyNotifications({required this.bodyStyle});

  final TextStyle bodyStyle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 40.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88.w,
              height: 88.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.35),
                  width: 2,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    color: AppColors.primary,
                    size: 36.sp,
                  ),
                  Positioned(
                    top: 18.h,
                    right: 22.w,
                    child: Container(
                      width: 10.w,
                      height: 10.w,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              'No Notifications',
              style: bodyStyle.copyWith(fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 8.h),
            Text(
              "We'll let you know when there's something to update you.",
              textAlign: TextAlign.center,
              style: bodyStyle.copyWith(color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.item,
    required this.bodyStyle,
    required this.onTap,
    required this.onDelete,
  });

  final AppNotificationModel item;
  final TextStyle bodyStyle;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20.w),
        color: AppColors.primary,
        child: Icon(Icons.delete_outline, color: AppColors.white, size: 22.sp),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onTap,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 14.h),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!item.isRead) ...[
                    Container(
                      width: 8.w,
                      height: 8.w,
                      margin: EdgeInsets.only(top: 18.h, right: 10.w),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ] else
                    SizedBox(width: 18.w),
                  CircleAvatar(
                    radius: 22.r,
                    backgroundColor: AppColors.surfaceLight,
                    child: Icon(
                      _iconForType(item.notificationType),
                      color: AppColors.primary,
                      size: 20.sp,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: bodyStyle.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (item.category.isNotEmpty) ...[
                          SizedBox(height: 2.h),
                          Text(
                            item.category,
                            style: bodyStyle.copyWith(
                              color: AppColors.primary,
                              fontSize: 11.sp,
                            ),
                          ),
                        ],
                        SizedBox(height: 6.h),
                        Text(
                          item.message,
                          style: bodyStyle.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                        SizedBox(height: 6.h),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 14.sp,
                              color: AppColors.textMuted,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              item.timestamp,
                              style: bodyStyle.copyWith(
                                color: AppColors.textMuted,
                                fontSize: 12.sp,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Divider(color: AppColors.border.withValues(alpha: 0.5), height: 1),
        ],
      ),
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'sos_activated':
        return Icons.warning_amber_rounded;
      case 'sos_cancelled':
        return Icons.check_circle_outline;
      default:
        return Icons.notifications_none;
    }
  }
}
