import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../router/routes.dart';

/// إشعار داخل التطبيق (In-App Notification)
/// يظهر عندما يكون التطبيق في المقدمة
class InAppNotification extends StatefulWidget {
  final String title;
  final String body;
  final String? avatarUrl;
  final Color? avatarColor;
  final String chatId;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;

  const InAppNotification({
    super.key,
    required this.title,
    required this.body,
    this.avatarUrl,
    this.avatarColor,
    required this.chatId,
    this.onTap,
    this.onDismiss,
  });

  @override
  State<InAppNotification> createState() => _InAppNotificationState();
}

class _InAppNotificationState extends State<InAppNotification>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimation();
    _startAnimation();
    _autoDismiss();
  }

  void _setupAnimation() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));
  }

  void _startAnimation() {
    _animationController.forward();
  }

  void _autoDismiss() {
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        _dismiss();
      }
    });
  }

  void _dismiss() {
    _animationController.reverse().then((_) {
      if (mounted && widget.onDismiss != null) {
        widget.onDismiss!();
      }
    });
  }

  void _handleTap() {
    if (widget.onTap != null) {
      widget.onTap!();
    } else {
      // التنقل الافتراضي إلى المحادثة
      context.go('${AppRoutes.chat}/${widget.chatId}');
    }
    _dismiss();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final avatarColor = widget.avatarColor ?? theme.colorScheme.primary;

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Material(
          color: Colors.transparent,
          child: GestureDetector(
            onTap: _handleTap,
            onPanUpdate: (details) {
              // إغلاق عند السحب لأعلى
              if (details.delta.dy < -5) {
                _dismiss();
              }
            },
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Avatar
                  Hero(
                    tag: 'notification_avatar_${widget.chatId}',
                    child: CircleAvatar(
                      radius: 24.r,
                      backgroundColor: avatarColor,
                      backgroundImage: widget.avatarUrl != null
                          ? NetworkImage(widget.avatarUrl!)
                          : null,
                      child: widget.avatarUrl == null
                          ? Text(
                              widget.title.isNotEmpty
                                  ? widget.title[0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          widget.body,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: 14.sp,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 8.w),
                  // Close button
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      size: 20.sp,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    onPressed: _dismiss,
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
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

/// Overlay Helper لإظهار إشعار داخل التطبيق
class InAppNotificationOverlay {
  static OverlayEntry? _overlayEntry;
  static OverlayState? _overlayState;

  /// إظهار إشعار داخل التطبيق
  static void show({
    required BuildContext context,
    required String title,
    required String body,
    String? avatarUrl,
    Color? avatarColor,
    required String chatId,
    VoidCallback? onTap,
  }) {
    // إخفاء أي إشعار سابق
    hide();

    _overlayState = Overlay.of(context);
    if (_overlayState == null) return;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 8,
        left: 0,
        right: 0,
        child: InAppNotification(
          title: title,
          body: body,
          avatarUrl: avatarUrl,
          avatarColor: avatarColor,
          chatId: chatId,
          onTap: onTap,
          onDismiss: hide,
        ),
      ),
    );

    _overlayState!.insert(_overlayEntry!);
  }

  /// إخفاء الإشعار
  static void hide() {
    if (_overlayEntry != null && _overlayState != null) {
      _overlayEntry!.remove();
      _overlayEntry = null;
      _overlayState = null;
    }
  }
}

