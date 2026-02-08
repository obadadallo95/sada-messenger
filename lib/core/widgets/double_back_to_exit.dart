import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sada/l10n/generated/app_localizations.dart';

/// Widget يمنع إغلاق التطبيق بالضغط مرة واحدة على زر Back
/// يتطلب الضغط مرتين خلال ثانيتين لإغلاق التطبيق
class DoubleBackToExit extends StatefulWidget {
  final Widget child;

  const DoubleBackToExit({
    super.key,
    required this.child,
  });

  @override
  State<DoubleBackToExit> createState() => _DoubleBackToExitState();
}

class _DoubleBackToExitState extends State<DoubleBackToExit> {
  DateTime? _lastPressed;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        final now = DateTime.now();
        final shouldExit = _lastPressed != null &&
            now.difference(_lastPressed!) < const Duration(seconds: 2);

        if (shouldExit) {
          // الضغط الثاني خلال ثانيتين - إغلاق التطبيق
          SystemNavigator.pop();
        } else {
          // الضغط الأول أو بعد ثانيتين - عرض رسالة
          _lastPressed = now;
          _showExitMessage(context);
          HapticFeedback.lightImpact();
        }
      },
      child: widget.child,
    );
  }

  /// عرض رسالة الخروج
  void _showExitMessage(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          l10n.exitMessage,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height * 0.1,
          left: 16.w,
          right: 16.w,
        ),
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.r),
        ),
      ),
    );
  }
}

