import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Widget لعرض الصورة الشخصية
/// يعرض الصورة من Base64 أو Initials إذا لم تكن موجودة
class UserAvatar extends StatelessWidget {
  final String? base64Image;
  final String userName;
  final double? radius;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const UserAvatar({
    super.key,
    this.base64Image,
    required this.userName,
    this.radius,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final defaultRadius = radius ?? 24.r;
    final defaultBgColor = backgroundColor ??
        _generateColorFromName(userName).withValues(alpha: 0.2);
    final defaultFgColor = foregroundColor ?? _generateColorFromName(userName);

    // إذا كانت هناك صورة Base64 صالحة، عرضها
    if (base64Image != null && base64Image!.isNotEmpty) {
      try {
        final imageBytes = base64Decode(base64Image!);
        return CircleAvatar(
          radius: defaultRadius,
          backgroundColor: Colors.transparent,
          backgroundImage: MemoryImage(imageBytes),
        );
      } catch (e) {
        // إذا فشل فك الترميز، عرض Initials
        return _buildInitialsAvatar(
          context,
          defaultRadius,
          defaultBgColor,
          defaultFgColor,
        );
      }
    }

    // عرض Initials
    return _buildInitialsAvatar(
      context,
      defaultRadius,
      defaultBgColor,
      defaultFgColor,
    );
  }

  /// بناء Avatar مع Initials
  Widget _buildInitialsAvatar(
    BuildContext context,
    double radius,
    Color bgColor,
    Color fgColor,
  ) {
    final initial = _getInitial(userName);

    return CircleAvatar(
      radius: radius,
      backgroundColor: bgColor,
      child: Text(
        initial,
        style: TextStyle(
          color: fgColor,
          fontSize: radius * 0.6,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// الحصول على الحرف الأول من الاسم
  String _getInitial(String name) {
    if (name.isEmpty) return '?';
    
    // إزالة المسافات والحصول على الحرف الأول
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    
    // إذا كان الاسم يحتوي على مسافات، أخذ الحرف الأول من كل كلمة
    final words = trimmed.split(' ');
    if (words.length > 1) {
      return (words[0][0] + words[1][0]).toUpperCase();
    }
    
    return trimmed[0].toUpperCase();
  }

  /// توليد لون من اسم المستخدم
  Color _generateColorFromName(String name) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.purple,
      Colors.orange,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
      Colors.red,
      Colors.amber,
      Colors.cyan,
    ];

    final index = name.hashCode % colors.length;
    return colors[index.abs()];
  }
}

