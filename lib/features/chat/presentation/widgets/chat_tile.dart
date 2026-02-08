import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sada/l10n/generated/app_localizations.dart';
import '../../domain/models/chat_model.dart';

/// Widget لعرض عنصر محادثة في القائمة
class ChatTile extends StatelessWidget {
  final ChatModel chat;
  final VoidCallback onTap;

  const ChatTile({
    super.key,
    required this.chat,
    required this.onTap,
  });

  /// تنسيق الوقت
  String _formatTime(BuildContext context, DateTime time) {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays == 0) {
      // نفس اليوم - عرض الوقت فقط
      final hour = time.hour;
      final minute = time.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    } else if (difference.inDays == 1) {
      return l10n.yesterday;
    } else if (difference.inDays < 7) {
      // استخدام intl message format
      final days = difference.inDays;
      return l10n.daysAgo(days);
    } else {
      // أكثر من أسبوع - عرض التاريخ
      return '${time.day}/${time.month}';
    }
  }

  /// الحصول على الحرف الأول من الاسم
  String _getInitial(String name) {
    if (name.isEmpty) return '?';
    return name[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 16.w,
          vertical: 12.h,
        ),
        child: Row(
          children: [
            // Avatar مع Hero animation
            Hero(
              tag: 'chat_avatar_${chat.id}',
              child: CircleAvatar(
                radius: 28.r,
                backgroundColor: Color(chat.avatarColor),
                child: Text(
                  _getInitial(chat.name),
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            SizedBox(width: 16.w),
            // المحتوى
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // الاسم
                      Expanded(
                        child: Text(
                          chat.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      // الوقت
                      Text(
                        _formatTime(context, chat.time),
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 12.sp,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  // آخر رسالة
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          chat.lastMessage ?? '',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: 14.sp,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (chat.unreadCount > 0) ...[
                        SizedBox(width: 8.w),
                        // Badge للرسائل غير المقروءة
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6.w,
                            vertical: 2.h,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                          constraints: BoxConstraints(
                            minWidth: 20.w,
                            minHeight: 20.h,
                          ),
                          child: Center(
                            child: Text(
                              chat.unreadCount > 99 ? '99+' : '${chat.unreadCount}',
                              style: TextStyle(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
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

