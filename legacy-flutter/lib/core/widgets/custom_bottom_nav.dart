import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_dimensions.dart';
import 'package:sada/l10n/generated/app_localizations.dart';

/// Bottom Navigation Bar مخصص
/// تصميم عصري مع أيقونات فقط (أو نصوص قصيرة جداً)
/// تأثير Glow عند الاختيار
class CustomBottomNav extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;
  final BuildContext context;

  const CustomBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
    required this.context,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Container(
      constraints: BoxConstraints(
        minHeight: 60.h,
        maxHeight: AppDimensions.bottomNavHeight,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.9),
        border: Border(
          top: BorderSide(
            color: AppColors.border,
            width: AppDimensions.borderWidth,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildNavItem(
              context: context,
              index: 0,
              icon: Icons.home_outlined,
              selectedIcon: Icons.home,
              label: l10n?.navigation_home ?? 'Home',
              isSelected: selectedIndex == 0,
            ),
            _buildNavItem(
              context: context,
              index: 1,
              icon: Icons.chat_bubble_outline,
              selectedIcon: Icons.chat_bubble,
              label: l10n?.navigation_chat ?? 'Chat',
              isSelected: selectedIndex == 1,
            ),
            _buildNavItem(
              context: context,
              index: 2,
              icon: Icons.group_outlined,
              selectedIcon: Icons.group,
              label: l10n?.navigation_communities ?? 'Groups',
              isSelected: selectedIndex == 2,
            ),
            _buildNavItem(
              context: context,
              index: 3,
              icon: Icons.person_add_outlined,
              selectedIcon: Icons.person_add,
              label: l10n?.navigation_add ?? 'Add',
              isSelected: selectedIndex == 3,
            ),
            _buildNavItem(
              context: context,
              index: 4,
              icon: Icons.settings_outlined,
              selectedIcon: Icons.settings,
              label: l10n?.navigation_settings ?? 'Settings',
              isSelected: selectedIndex == 4,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required int index,
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    required bool isSelected,
  }) {
    return Expanded(
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onItemTapped(index);
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            // حساب المساحة المتاحة وتعديل الأحجام حسبها
            final availableHeight = constraints.maxHeight;
            final isSmallScreen = availableHeight < 60;
            
            return Container(
              padding: EdgeInsets.symmetric(
                vertical: isSmallScreen ? 4.h : 6.h,
                horizontal: 2.w,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // أيقونة مع تأثير Glow عند الاختيار
                  Flexible(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      padding: EdgeInsets.all(isSelected ? 6.w : 3.w),
                      constraints: BoxConstraints(
                        maxWidth: isSmallScreen ? 32.w : 40.w,
                        maxHeight: isSmallScreen ? 32.h : 40.h,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary.withValues(alpha: 0.2)
                            : Colors.transparent,
                        shape: BoxShape.circle,
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.3),
                                  blurRadius: 12,
                                  spreadRadius: 2,
                                ),
                              ]
                            : null,
                      ),
                      child: Icon(
                        isSelected ? selectedIcon : icon,
                        size: isSmallScreen ? 20.w : AppDimensions.iconSizeMd,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 2.h : 4.h),
                  // نص صغير جداً
                  Flexible(
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: AppTypography.labelSmall(context).copyWith(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textTertiary,
                        fontSize: isSmallScreen 
                            ? (isSelected ? 9.sp : 8.sp)
                            : (isSelected ? 11.sp : 10.sp),
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                      child: Text(
                        _getShortLabel(label),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        softWrap: false,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// الحصول على نص مختصر للعرض
  String _getShortLabel(String label) {
    // إذا كان النص طويلاً، نختصره
    if (label.length > 8) {
      // للعربية: نأخذ أول 6 أحرف
      // للإنجليزية: نأخذ أول 6 أحرف
      return label.substring(0, 6);
    }
    return label;
  }
}

