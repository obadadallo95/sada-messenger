import 'package:flutter/material.dart';

import '../utils/log_service.dart';

/// Widget للخروج من Duress Mode عبر نقر ثلاثي على الشعار
class HiddenExitGesture extends StatefulWidget {
  final Widget child;
  final VoidCallback? onExitGesture;

  const HiddenExitGesture({super.key, required this.child, this.onExitGesture});

  @override
  State<HiddenExitGesture> createState() => _HiddenExitGestureState();
}

class _HiddenExitGestureState extends State<HiddenExitGesture> {
  int _tapCount = 0;
  DateTime? _lastTap;
  static const _tapWindow = Duration(seconds: 2); // نافذة زمنية للنقرات
  static const _requiredTaps = 3; // عدد النقرات المطلوبة

  void _handleTap() {
    final now = DateTime.now();

    // التحقق من أن النقرة ضمن النافذة الزمنية
    if (_lastTap != null && now.difference(_lastTap!) < _tapWindow) {
      _tapCount++;
      LogService.info('Hidden gesture tap count: $_tapCount');

      if (_tapCount >= _requiredTaps) {
        _onExitGestureDetected();
        _tapCount = 0; // إعادة تعيين العداد
      }
    } else {
      // بدء تسلسل جديد
      _tapCount = 1;
    }

    _lastTap = now;
  }

  void _onExitGestureDetected() {
    LogService.info('🔓 Hidden exit gesture detected - showing PIN dialog');

    // استدعاء callback إذا تم توفيره
    if (widget.onExitGesture != null) {
      widget.onExitGesture!();
    } else {
      // عرض dialog لإعادة إدخال PIN
      _showPinDialog();
    }
  }

  void _showPinDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('إعادة المصادقة'),
        content: const Text(
          'للخروج من الوضع الحالي، يرجى إدخال رمز PIN الخاص بك.',
          textAlign: TextAlign.right,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // يمكن إضافة منطق لإعادة توجيه المستخدم إلى شاشة PIN
              // أو إعادة تشغيل التطبيق
              LogService.info('User requested PIN re-entry');
            },
            child: const Text('موافق'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      behavior: HitTestBehavior.translucent,
      child: widget.child,
    );
  }
}
