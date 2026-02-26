import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_dimensions.dart';

/// مكون حالة الفراغ (Empty State)
/// يعرض رسالة عندما لا توجد بيانات مع Call to Action
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color? iconColor;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveIconColor = iconColor ?? AppColors.primary.withValues(alpha: 0.5);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxHeight < 600;
        
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
            ),
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(
                  isSmallScreen ? AppDimensions.paddingMd : AppDimensions.paddingXl,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // أيقونة كبيرة مع تأثير طفو
                    Icon(
                      icon,
                      size: isSmallScreen 
                          ? AppDimensions.emptyStateIconSize * 0.7
                          : AppDimensions.emptyStateIconSize,
                      color: effectiveIconColor,
                    )
                .animate(onPlay: (controller) => controller.repeat())
                .shimmer(
                  duration: 2000.ms,
                  color: AppColors.primary.withValues(alpha: 0.3),
                )
                .then()
                .moveY(
                  begin: 0,
                  end: -10,
                  duration: 2000.ms,
                  curve: Curves.easeInOut,
                )
                .then()
                .moveY(
                  begin: -10,
                  end: 0,
                  duration: 2000.ms,
                  curve: Curves.easeInOut,
                ),

                    SizedBox(height: isSmallScreen ? AppDimensions.spacingMd : AppDimensions.spacingLg),

                    // العنوان
                    Text(
                      title,
                      style: AppTypography.headlineMedium(context),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    SizedBox(height: isSmallScreen ? AppDimensions.spacingSm : AppDimensions.spacingMd),

                    // الوصف
                    Text(
                      subtitle,
                      style: AppTypography.bodyLarge(context),
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // زر CTA (إذا كان متوفراً)
                    if (actionLabel != null && onAction != null) ...[
                      SizedBox(height: isSmallScreen ? AppDimensions.spacingMd : AppDimensions.spacingXl),
                      _AnimatedButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          onAction?.call();
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add, size: AppDimensions.iconSizeMd),
                            SizedBox(width: AppDimensions.spacingSm),
                            Flexible(
                              child: Text(
                                actionLabel!,
                                style: AppTypography.buttonLarge(context),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// زر متحرك مع تأثير Scale عند الضغط
class _AnimatedButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;

  const _AnimatedButton({
    required this.onPressed,
    required this.child,
  });

  @override
  State<_AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<_AnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onPressed?.call();
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: ElevatedButton(
          onPressed: widget.onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.onPrimary,
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.paddingLg,
              vertical: AppDimensions.paddingMd,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
            ),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

