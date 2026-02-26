import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Widget للوغو التطبيق
/// يمكن استخدامه في أي مكان في التطبيق
class AppLogo extends StatelessWidget {
  final double? width;
  final double? height;
  final BoxFit fit;

  const AppLogo({
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    // محاولة استخدام logo.png أولاً، ثم applogo.png كبديل
    return Image.asset(
      'assets/images/logo.png',
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        // في حالة عدم وجود logo.png، جرب applogo.png
        return Image.asset(
          'assets/images/applogo.png',
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) {
            // في حالة عدم وجود أي صورة، نعرض أيقونة بديلة
            return Icon(
              Icons.wifi_tethering,
              size: width ?? 120.sp,
              color: Theme.of(context).colorScheme.primary,
            );
          },
        );
      },
    );
  }
}

