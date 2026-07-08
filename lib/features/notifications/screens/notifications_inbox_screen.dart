import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:saefra_run/core/constants/app_colors.dart';
import 'package:saefra_run/core/models/notification_model.dart';
import 'package:saefra_run/core/services/notification_inbox_service.dart';
import 'package:saefra_run/core/widgets/app_page_header.dart';

class NotificationsInboxScreen extends StatelessWidget {
  const NotificationsInboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final inbox = context.watch<NotificationInboxService>();
    final textTheme = Theme.of(context).textTheme;

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
                      onPressed: inbox.clearAll,
                      child: Text(
                        'Clear All',
                        style: textTheme.labelLarge?.copyWith(
                          color: AppColors.primary,
                          fontSize: 10.sp,
                        ),
                      ),
                    ),
            ),
            Expanded(
              child: inbox.isEmpty
                  ? _EmptyNotifications(textTheme: textTheme)
                  : ListView(
                      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h),
                      children: [
                        Text(
                          'You have ${inbox.todayUnreadCount} New notifications total',
                          style: textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                              color: AppColors.white
                          ),
                        ),
                        SizedBox(height: 16.h),
                        ...inbox.items.map(
                          (item) => _NotificationTile(
                            item: item,
                            onTap: () => inbox.markRead(item.id),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyNotifications extends StatelessWidget {
  const _EmptyNotifications({required this.textTheme});

  final TextTheme textTheme;

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
            Text('No Notifications', style: textTheme.titleLarge),
            SizedBox(height: 8.h),
            Text(
              "We'll let you know when there's something to update you.",
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.item, required this.onTap});

  final AppNotificationModel item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
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
                  child: Text(
                    item.userName.isNotEmpty ? item.userName[0] : '?',
                    style: textTheme.titleMedium,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: TextSpan(
                          style: textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                          children: [
                            TextSpan(
                              text: item.userName,
                              style: textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            TextSpan(text: ' ${item.message}'),
                          ],
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
                            style: textTheme.bodySmall,
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
    );
  }
}
