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
      final hour = time.hour;
      final minute = time.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    } else if (difference.inDays == 1) {
      return l10n.yesterday;
    } else if (difference.inDays < 7) {
      return l10n.daysAgo(difference.inDays);
    } else {
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
    // Assuming presence of publicKey means verified/secure contact
    final isVerified = chat.publicKey != null; 

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: theme.colorScheme.primary.withValues(alpha: 0.1),
        highlightColor: theme.colorScheme.primary.withValues(alpha: 0.05),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 16.w,
            vertical: 16.h,
          ),
          child: Row(
            children: [
              // Avatar مع Hero animation
              Hero(
                tag: 'chat_avatar_${chat.id}',
                child: Container(
                  width: 56.w,
                  height: 56.w,
                  decoration: BoxDecoration(
                    color: Color(chat.avatarColor),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isVerified ? theme.colorScheme.primary : Colors.transparent,
                      width: 2.w,
                    ),
                    boxShadow: isVerified ? [
                      BoxShadow(
                        color: theme.colorScheme.primary.withValues(alpha: 0.4),
                        blurRadius: 8,
                        spreadRadius: 1,
                      )
                    ] : [],
                  ),
                  child: Center(
                    child: Text(
                      _getInitial(chat.name),
                      style: TextStyle(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 16.w),
              // المحتوى - الاسم والرسالة
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // الاسم + شارة التوثيق
                        Expanded(
                          child: Row(
                            children: [
                              Flexible(
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
                              if (isVerified) ...[
                                SizedBox(width: 4.w),
                                Icon(
                                  Icons.verified_user_rounded,
                                  size: 14.sp,
                                  color: theme.colorScheme.primary,
                                ),
                              ],
                            ],
                          ),
                        ),
                        SizedBox(width: 8.w),
                        // الوقت
                        Text(
                          _formatTime(context, chat.time),
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 12.sp,
                            color: theme.colorScheme.onSurfaceVariant,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 6.h),
                    // آخر رسالة + Badge
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            chat.lastMessage ?? 'لا توجد رسائل',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontSize: 14.sp,
                              color: chat.unreadCount > 0 
                                  ? theme.colorScheme.onSurface 
                                  : theme.colorScheme.onSurfaceVariant,
                              fontWeight: chat.unreadCount > 0 
                                  ? FontWeight.w600 
                                  : FontWeight.normal,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (chat.unreadCount > 0) ...[
                          SizedBox(width: 8.w),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.w,
                              vertical: 4.h,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              borderRadius: BorderRadius.circular(12.r),
                              boxShadow: [
                                BoxShadow(
                                  color: theme.colorScheme.primary.withValues(alpha: 0.4),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            constraints: BoxConstraints(
                              minWidth: 24.w,
                              minHeight: 24.h,
                            ),
                            child: Center(
                              child: Text(
                                chat.unreadCount > 99 ? '99+' : '${chat.unreadCount}',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
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
      ),
    );
  }
}
