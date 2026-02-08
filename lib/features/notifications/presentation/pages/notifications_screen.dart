import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:sada/l10n/generated/app_localizations.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/widgets/user_avatar.dart';

/// نموذج إشعار
class NotificationModel {
  final String id;
  final String title;
  final String body;
  final DateTime timestamp;
  final String? chatId;
  final bool isRead;
  final Color? avatarColor;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    this.chatId,
    this.isRead = false,
    this.avatarColor,
  });
}

/// Provider للإشعارات (Mock Data للاختبار)
final notificationsProvider = Provider<List<NotificationModel>>((ref) {
  // في المستقبل، سيتم جلب الإشعارات من قاعدة البيانات
  return [];
});

/// شاشة الإشعارات
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } else if (difference.inDays > 0) {
      return 'منذ ${difference.inDays} ${difference.inDays == 1 ? 'يوم' : 'أيام'}';
    } else if (difference.inHours > 0) {
      return 'منذ ${difference.inHours} ${difference.inHours == 1 ? 'ساعة' : 'ساعات'}';
    } else if (difference.inMinutes > 0) {
      return 'منذ ${difference.inMinutes} ${difference.inMinutes == 1 ? 'دقيقة' : 'دقائق'}';
    } else {
      return 'الآن';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final notifications = ref.watch(notificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.notifications),
        centerTitle: true,
        actions: [
          if (notifications.isNotEmpty)
            TextButton(
              onPressed: () {
                // Mark all as read
                // سيتم تنفيذها لاحقاً
              },
              child: Text(
                l10n.markAllAsRead,
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontSize: 14.sp,
                ),
              ),
            ),
        ],
      ),
      body: notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 64.sp,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    l10n.noNotifications,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: 18.sp,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.symmetric(vertical: 8.h),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return Dismissible(
                  key: Key(notification.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.error,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(
                      Icons.delete_outline,
                      color: Colors.white,
                      size: 24.sp,
                    ),
                  ),
                  onDismissed: (direction) {
                    // حذف الإشعار
                    // سيتم تنفيذها لاحقاً
                  },
                  child: Card(
                    margin: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 4.h,
                    ),
                    child: InkWell(
                      onTap: () {
                        if (notification.chatId != null) {
                          context.push(
                            '${AppRoutes.chat}/${notification.chatId}',
                          );
                        }
                      },
                      child: Padding(
                        padding: EdgeInsets.all(16.w),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Avatar
                            UserAvatar(
                              userName: notification.title,
                              radius: 24.r,
                              backgroundColor: notification.avatarColor ??
                                  theme.colorScheme.primary,
                            ),
                            SizedBox(width: 12.w),
                            // Content
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          notification.title,
                                          style: theme.textTheme.titleMedium?.copyWith(
                                            fontSize: 16.sp,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      if (!notification.isRead)
                                        Container(
                                          width: 8.w,
                                          height: 8.h,
                                          decoration: BoxDecoration(
                                            color: theme.colorScheme.primary,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                    ],
                                  ),
                                  SizedBox(height: 4.h),
                                  Text(
                                    notification.body,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontSize: 14.sp,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 8.h),
                                  Text(
                                    _formatTime(notification.timestamp),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontSize: 12.sp,
                                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

