import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:ui';
import '../../domain/models/message_model.dart';

/// Widget لعرض فقاعة الرسالة
/// Cyber-Stealth aesthetic with glassmorphism
class MessageBubble extends StatelessWidget {
  final MessageModel message;

  const MessageBubble({super.key, required this.message});

  /// تنسيق الوقت
  String _formatTime(DateTime timestamp) {
    final hour = timestamp.hour;
    final minute = timestamp.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// أيقونة حالة الرسالة
  Widget _buildStatusIcon(MessageStatus status, BuildContext context) {
    final theme = Theme.of(context);
    switch (status) {
      case MessageStatus.draft:
        return Icon(
          Icons.schedule,
          size: 14.sp,
          color: Colors.white.withValues(alpha: 0.5),
        );
      case MessageStatus.sending:
        return Icon(
          Icons.schedule,
          size: 14.sp,
          color: Colors.white.withValues(alpha: 0.7),
        );
      case MessageStatus.sent:
        return Icon(
          Icons.rocket_launch,
          size: 14.sp,
          color: Colors.white.withValues(alpha: 0.7),
        );
      case MessageStatus.delivered:
        return Icon(
          Icons.done_all,
          size: 14.sp,
          color: Colors.white.withValues(alpha: 0.7),
        );
      case MessageStatus.read:
        return Icon(
          Icons.done_all,
          size: 14.sp,
          color: theme.colorScheme.secondary,
        );
      case MessageStatus.failed:
        return Icon(
          Icons.error_outline,
          size: 14.sp,
          color: theme.colorScheme.error,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (message.isMe) {
      // رسالتي - Gradient (Cyan to Blue) with rounded corners
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          margin: EdgeInsets.only(
            left: 48.w,
            right: 16.w,
            top: 4.h,
            bottom: 4.h,
          ),
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary, // Electric Cyan
                theme.colorScheme.primary.withValues(alpha: 0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24.r),
              topRight: Radius.circular(24.r),
              bottomLeft: Radius.circular(24.r),
              bottomRight: Radius.circular(4.r),
            ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                message.text,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: Colors.black,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 6.h),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: Colors.black.withValues(alpha: 0.7),
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  SizedBox(width: 6.w),
                  _buildStatusIcon(message.status, context),
                ],
              ),
            ],
          ),
        ),
      );
    } else {
      // رسالة الطرف الآخر - Glassmorphism dark container
      return Align(
        alignment: Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          margin: EdgeInsets.only(
            left: 16.w,
            right: 48.w,
            top: 4.h,
            bottom: 4.h,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24.r),
              topRight: Radius.circular(24.r),
              bottomLeft: Radius.circular(4.r),
              bottomRight: Radius.circular(24.r),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface.withValues(alpha: 0.4),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                    width: 1,
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24.r),
                    topRight: Radius.circular(24.r),
                    bottomLeft: Radius.circular(4.r),
                    bottomRight: Radius.circular(24.r),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message.text,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      _formatTime(message.timestamp),
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: Colors.white.withValues(alpha: 0.6),
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }
  }
}
