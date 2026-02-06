import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/biometric_service.dart';
import '../../../../core/widgets/app_logo.dart';
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

    // التحقق من حالة المصادقة
    final authStatus = ref.read(authServiceProvider);
    
    // انتظار حتى يتم التهيئة
    if (authStatus == AuthStatus.initializing) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
    }

    final isLoggedIn = ref.read(authServiceProvider) == AuthStatus.loggedIn;

    if (!mounted) return;

    if (!isLoggedIn) {
      // غير مسجل دخول - الانتقال إلى صفحة التسجيل
      context.go(AppRoutes.register);
      return;
    }

    // مسجل دخول - التحقق من قفل التطبيق
    final biometricState = ref.read(biometricServiceProvider);
    if (biometricState.isAppLockEnabled) {
      // قفل التطبيق مفعل - الانتقال إلى Lock Screen
      context.go(AppRoutes.lock);
      return;
    }

    // مسجل دخول وليس مقفل - التحقق من Onboarding
    final onboardingStatus = await ref.read(onboardingRepositoryProvider.future);

    if (!mounted) return;

    if (onboardingStatus) {
      // Onboarding مكتمل - الانتقال إلى Home
      context.go(AppRoutes.home);
    } else {
      // Onboarding غير مكتمل - الانتقال إلى Onboarding
      context.go(AppRoutes.onboarding);
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
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.primaryContainer,
            ],
          ),
        ),
        child: SafeArea(
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
              const Spacer(),
              // Loading indicator في الأسفل
              Padding(
                padding: EdgeInsets.only(bottom: 40.h),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

