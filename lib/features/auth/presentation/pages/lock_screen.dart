import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/biometric_service.dart';
import '../../../../core/database/database_provider.dart';
import '../../../../l10n/app_localizations.dart';

/// شاشة قفل التطبيق
/// تطلب المصادقة البيومترية أو PIN للدخول
class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  bool _isAuthenticating = false;
  String _enteredPin = '';
  final int _maxPinLength = 6;
  bool _showPinPad = false;

  @override
  void initState() {
    super.initState();
    // محاولة المصادقة البيومترية تلقائياً عند فتح الشاشة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tryBiometricAuth();
    });
  }

  Future<void> _tryBiometricAuth() async {
    if (_isAuthenticating) return;

    final biometricState = ref.read(biometricServiceProvider);
    if (!biometricState.isAvailable) {
      // إذا لم تكن البصمة متاحة، عرض PIN Pad
      setState(() {
        _showPinPad = true;
      });
      return;
    }

    setState(() {
      _isAuthenticating = true;
    });

    final biometricService = ref.read(biometricServiceProvider.notifier);
    final l10n = AppLocalizations.of(context)!;

    final success = await biometricService.authenticate(
      reason: l10n.scanFingerprintToEnter,
    );

    if (!mounted) return;

    setState(() {
      _isAuthenticating = false;
    });

    if (success) {
      // نجحت المصادقة البيومترية - استخدام Master PIN افتراضياً
      await _handleSuccessfulAuth(AuthType.master);
    } else {
      // فشلت المصادقة - عرض PIN Pad
      setState(() {
        _showPinPad = true;
      });
    }
  }

  void _onPinDigitPressed(String digit) {
    if (_enteredPin.length < _maxPinLength) {
      setState(() {
        _enteredPin += digit;
      });

      // إذا تم إدخال PIN كامل، التحقق منه
      if (_enteredPin.length == _maxPinLength) {
        _verifyPin();
      }
    }
  }

  void _onPinBackspace() {
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
      });
    }
  }

  Future<void> _verifyPin() async {
    if (_isAuthenticating) return;

    setState(() {
      _isAuthenticating = true;
    });

    final authService = ref.read(authServiceProvider.notifier);
    final authType = await authService.verifyPin(_enteredPin);

    if (!mounted) return;

    setState(() {
      _isAuthenticating = false;
    });

    if (authType == AuthType.failure) {
      // PIN غير صحيح - Shake animation
      setState(() {
        _enteredPin = '';
      });
      HapticFeedback.heavyImpact();
    } else {
      // PIN صحيح - معالجة المصادقة الناجحة
      await _handleSuccessfulAuth(authType);
    }
  }

  Future<void> _handleSuccessfulAuth(AuthType authType) async {
    try {
      // حفظ نوع المصادقة في Provider
      ref.read(currentAuthTypeProvider.notifier).state = authType;
      
      // تهيئة قاعدة البيانات بناءً على نوع المصادقة
      final dbInitializer = ref.read(databaseInitializerProvider);
      await dbInitializer.initializeDatabase(authType);

      if (!mounted) return;

      // الانتقال إلى Home مع fade transition
      // ⚠️ مهم: لا تظهر أي رسالة مختلفة في Duress Mode
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) {
            // سيتم توجيهه تلقائياً إلى Home من Router
            return Container(); // Placeholder
          },
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 300),
        ),
      );

      // الانتقال إلى Home
      context.go(AppRoutes.home);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في تهيئة قاعدة البيانات: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final biometricState = ref.watch(biometricServiceProvider);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primary,
              theme.colorScheme.primaryContainer,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(24.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Lock Icon
                  Container(
                    width: 120.w,
                    height: 120.h,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.lock_outline,
                      size: 64.sp,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 32.h),
                  
                  // Title
                  Text(
                    l10n.sadaIsLocked,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontSize: 28.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16.h),
                  
                  // Subtitle
                  Text(
                    l10n.unlockToContinue,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontSize: 16.sp,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 48.h),
                  
                  // PIN Dots
                  if (_showPinPad)
                    _buildPinDots()
                        .animate(target: _enteredPin.isEmpty ? 0 : 1)
                        .shake(
                          duration: const Duration(milliseconds: 500),
                          hz: 4,
                          curve: Curves.easeInOut,
                        )
                  else
                    SizedBox(height: 24.h),
                  
                  SizedBox(height: 24.h),
                  
                  // Biometric Button (if available and PIN Pad not shown)
                  if (!_showPinPad && biometricState.isAvailable)
                    SizedBox(
                      width: double.infinity,
                      height: 56.h,
                      child: ElevatedButton.icon(
                        onPressed: _isAuthenticating ? null : _tryBiometricAuth,
                        icon: _isAuthenticating
                            ? SizedBox(
                                width: 20.w,
                                height: 20.h,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Icon(
                                Icons.fingerprint,
                                size: 24.sp,
                              ),
                        label: Text(
                          l10n.unlock,
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: theme.colorScheme.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                      ),
                    ),
                  
                  // PIN Pad
                  if (_showPinPad) ...[
                    SizedBox(height: 32.h),
                    _buildPinPad(),
                  ],
                  
                  // Switch to PIN (if biometric available)
                  if (!_showPinPad && biometricState.isAvailable)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _showPinPad = true;
                        });
                      },
                      child: Text(
                        l10n.enterPin,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 14.sp,
                        ),
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

  /// بناء PIN Dots
  Widget _buildPinDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        _maxPinLength,
        (index) => Container(
          width: 16.w,
          height: 16.h,
          margin: EdgeInsets.symmetric(horizontal: 8.w),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: index < _enteredPin.length
                ? Colors.white
                : Colors.white.withValues(alpha: 0.3),
          ),
        ),
      ),
    );
  }

  /// بناء PIN Pad
  Widget _buildPinPad() {
    return Column(
      children: [
        // Row 1-3
        for (int row = 0; row < 3; row++)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 8.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (int col = 1; col <= 3; col++)
                  _buildPinButton('${row * 3 + col}'),
              ],
            ),
          ),
        // Row 4 (0 and Backspace)
        Padding(
          padding: EdgeInsets.symmetric(vertical: 8.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildPinButton('0'),
              _buildPinButton('', isBackspace: true),
            ],
          ),
        ),
      ],
    );
  }

  /// بناء زر PIN
  Widget _buildPinButton(String digit, {bool isBackspace = false}) {
    return Container(
      width: 70.w,
      height: 70.h,
      margin: EdgeInsets.symmetric(horizontal: 8.w),
      child: Material(
        color: Colors.white.withValues(alpha: 0.2),
        shape: const CircleBorder(),
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            if (isBackspace) {
              _onPinBackspace();
            } else {
              _onPinDigitPressed(digit);
            }
          },
          customBorder: const CircleBorder(),
          child: Center(
            child: isBackspace
                ? Icon(
                    Icons.backspace,
                    color: Colors.white,
                    size: 24.sp,
                  )
                : Text(
                    digit,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
