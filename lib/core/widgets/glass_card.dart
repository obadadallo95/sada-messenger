import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';

/// بطاقة زجاجية (Glassmorphism)
/// تأثير زجاجي مع ضبابية وحدود شفافة
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? borderRadius;
  final Color? borderColor;
  final VoidCallback? onTap;
  final Color? backgroundColor;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius,
    this.borderColor,
    this.onTap,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBorderRadius = borderRadius ?? AppDimensions.radiusLg;
    final effectivePadding = padding ?? const EdgeInsets.all(AppDimensions.paddingMd);
    final effectiveBorderColor = borderColor ?? AppColors.primary.withValues(alpha: 0.2);
    final effectiveBackgroundColor = backgroundColor ?? AppColors.surface.withValues(alpha: 0.7);

    Widget cardContent = Container(
      decoration: BoxDecoration(
        color: effectiveBackgroundColor,
        borderRadius: BorderRadius.circular(effectiveBorderRadius),
        border: Border.all(
          color: effectiveBorderColor,
          width: AppDimensions.borderWidth,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.1),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(effectiveBorderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: effectivePadding,
            child: child,
          ),
        ),
      ),
    );

    if (onTap != null) {
      cardContent = InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap?.call();
        },
        borderRadius: BorderRadius.circular(effectiveBorderRadius),
        child: cardContent,
      );
    }
    
    // إضافة animation fade-in عند الظهور
    cardContent = cardContent
        .animate()
        .fadeIn(duration: 300.ms)
        .slideY(begin: 0.1, end: 0, duration: 300.ms, curve: Curves.easeOut);

    if (margin != null) {
      cardContent = Padding(
        padding: margin!,
        child: cardContent,
      );
    }

    return cardContent;
  }
}

