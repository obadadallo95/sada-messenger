import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/biometric_service.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../core/utils/log_service.dart';
import '../../../onboarding/data/repositories/onboarding_repository.dart';

/// شاشة البداية (Splash Screen)
/// تعرض شعار التطبيق مع animation ثم تنتقل إلى Onboarding أو Home
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimation();
    _navigateAfterDelay();
  }

  void _setupAnimation() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // Fade In animation
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
    ));

    // Scale Up animation
    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
    ));

    _animationController.forward();
  }

  Future<void> _navigateAfterDelay() async {
    // انتظار ثانيتين (محاكاة للتحقق من الخدمات)
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    LogService.info('🚀 بدء التنقل من Splash Screen');

    // انتظار حتى يتم التهيئة (مع timeout)
    int maxRetries = 20; // 20 محاولة × 500ms = 10 ثواني كحد أقصى
    int retryCount = 0;
    
    while (retryCount < maxRetries) {
      final authStatus = ref.read(authServiceProvider);
      LogService.info('📊 حالة المصادقة: $authStatus (محاولة ${retryCount + 1}/$maxRetries)');
      
      if (authStatus != AuthStatus.initializing) {
        LogService.info('✅ اكتملت التهيئة - الحالة: $authStatus');
        break; // التهيئة اكتملت
      }
      
      await Future.delayed(const Duration(milliseconds: 500));
      retryCount++;
      
      if (!mounted) return;
    }

    if (!mounted) return;

    final authStatus = ref.read(authServiceProvider);
    
    // Fallback: إذا استمرت التهيئة، نعتبر المستخدم غير مسجل دخول
    if (authStatus == AuthStatus.initializing) {
      LogService.warning('⚠️ انتهى timeout التهيئة - الانتقال إلى Register كحل افتراضي');
      if (mounted) {
        context.go(AppRoutes.register);
      }
      return;
    }
    
    final isLoggedIn = authStatus == AuthStatus.loggedIn;
    
    LogService.info('🔐 حالة تسجيل الدخول النهائية: $authStatus (isLoggedIn: $isLoggedIn)');

    if (!mounted) return;

    if (!isLoggedIn) {
      // غير مسجل دخول - الانتقال إلى صفحة التسجيل
      LogService.info('➡️ الانتقال إلى صفحة التسجيل');
      if (mounted) {
        context.go(AppRoutes.register);
      }
      return;
    }

    // مسجل دخول - التحقق من قفل التطبيق
    final biometricState = ref.read(biometricServiceProvider);
    LogService.info('🔒 حالة قفل التطبيق: ${biometricState.isAppLockEnabled}');
    
    if (biometricState.isAppLockEnabled) {
      // قفل التطبيق مفعل - الانتقال إلى Lock Screen
      LogService.info('➡️ الانتقال إلى Lock Screen');
      if (mounted) {
        context.go(AppRoutes.lock);
      }
      return;
    }

    // مسجل دخول وليس مقفل - التحقق من Onboarding
    LogService.info('📋 التحقق من حالة Onboarding...');
    try {
      final onboardingStatus = await ref.read(onboardingRepositoryProvider.future)
          .timeout(const Duration(seconds: 5));

      if (!mounted) return;

      LogService.info('📋 حالة Onboarding: $onboardingStatus');

      if (onboardingStatus) {
        // Onboarding مكتمل - الانتقال إلى Home
        LogService.info('➡️ الانتقال إلى Home Screen');
        if (mounted) {
          context.go(AppRoutes.home);
        }
      } else {
        // Onboarding غير مكتمل - الانتقال إلى Onboarding
        LogService.info('➡️ الانتقال إلى Onboarding Screen');
        if (mounted) {
          context.go(AppRoutes.onboarding);
        }
      }
    } catch (e) {
      // في حالة الخطأ، الانتقال إلى Onboarding كحل افتراضي
      LogService.error('خطأ في تحميل حالة Onboarding', e);
      LogService.info('➡️ الانتقال إلى Onboarding Screen (fallback)');
      if (mounted) {
        context.go(AppRoutes.onboarding);
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          // Cyber-Stealth: Deep Midnight Blue background (matches native splash)
          color: Color(0xFF050A14),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // شعار التطبيق مع FadeIn و Scale Up animations
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: AppLogo(
                      width: 200.w,
                      height: 200.h,
                    ),
                  ),
                ),
                SizedBox(height: 32.h),
                // اسم التطبيق
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Text(
                    'Sada',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          fontSize: 48.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                  ),
                ),
                SizedBox(height: 60.h),
                // Loading indicator
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

