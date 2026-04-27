import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:lottie/lottie.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/widgets/mesh_gradient_background.dart';
import '../../../../core/router/routes.dart';
import '../../data/repositories/onboarding_repository.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _controller = PageController();
  bool _isLastPage = false;
  bool _isRequestingBattery = false;

  Future<void> _completeAndGoRegister() async {
    await ref.read(onboardingRepositoryProvider.notifier).completeOnboarding();
    if (!mounted) return;
    context.go(AppRoutes.register);
  }

  Future<void> _requestBatteryExemption() async {
    if (!Platform.isAndroid || _isRequestingBattery) return;

    setState(() {
      _isRequestingBattery = true;
    });

    try {
      var status = await Permission.ignoreBatteryOptimizations.status;
      if (!status.isGranted) {
        status = await Permission.ignoreBatteryOptimizations.request();
      }

      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);

      if (status.isGranted) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('تم تفعيل استثناء تحسين البطارية بنجاح'),
          ),
        );
      } else {
        final opened = await openAppSettings();
        if (!opened && mounted) {
          messenger.showSnackBar(
            const SnackBar(
              content: Text(
                'تعذر فتح الإعدادات. يرجى تعطيل تحسين البطارية يدوياً',
              ),
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRequestingBattery = false;
        });
      }
    }
  }

  final List<OnboardingPageModel> _pages = [
    OnboardingPageModel(
      title: 'تواصل بلا حدود',
      description: 'صدى يعمل حتى عند انقطاع الإنترنت. شبكتك هي الناس من حولك.',
      lottieAsset: 'assets/json/Global Network.json',
      color: Colors.cyanAccent,
    ),
    OnboardingPageModel(
      title: 'شبكة البشر (Mesh)',
      description:
          'رسائلك تقفز من هاتف لآخر عبر WiFi و Bluetooth حتى تصل لصديقك البعيد.',
      lottieAsset: 'assets/json/Global Network.json',
      color: Colors.purpleAccent,
    ),
    OnboardingPageModel(
      title: 'أمان وتشفير تام',
      description:
          'لا خوادم مركزية. رسائلك مشفرة ولا يمكن لأحد قراءتها غيرك أنت والمستلم.',
      lottieAsset: 'assets/json/data security.json',
      color: Colors.greenAccent,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MeshGradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            // Page View
            PageView.builder(
              controller: _controller,
              itemCount: _pages.length,
              onPageChanged: (index) {
                setState(() {
                  _isLastPage = index == _pages.length - 1;
                });
              },
              itemBuilder: (context, index) {
                return _buildPage(context, _pages[index]);
              },
            ),

            // Bottom Controls
            Positioned(
              bottom: 40.h,
              left: 20.w,
              right: 20.w,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isLastPage && Platform.isAndroid)
                    Padding(
                      padding: EdgeInsets.only(bottom: 12.h),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isRequestingBattery
                              ? null
                              : _requestBatteryExemption,
                          icon: _isRequestingBattery
                              ? SizedBox(
                                  width: 16.w,
                                  height: 16.h,
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.battery_alert_outlined),
                          label: const Text(
                            'تعطيل تحسين البطارية (مهم للشبكة)',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.errorContainer,
                            foregroundColor: theme.colorScheme.onErrorContainer,
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                          ),
                        ),
                      ),
                    ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Indicators
                      SmoothPageIndicator(
                        controller: _controller,
                        count: _pages.length,
                        effect: ExpandingDotsEffect(
                          activeDotColor: theme.colorScheme.primary,
                          dotColor: Colors.white24,
                          dotHeight: 8.h,
                          dotWidth: 8.w,
                          spacing: 8.w,
                        ),
                      ),

                      // Next / Done Button
                      ElevatedButton(
                        onPressed: () {
                          if (_isLastPage) {
                            _completeAndGoRegister();
                          } else {
                            _controller.nextPage(
                              duration: const Duration(milliseconds: 500),
                              curve: Curves.easeInOut,
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          shape: const CircleBorder(),
                          padding: EdgeInsets.all(16.w),
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: Colors.black,
                        ),
                        child: Icon(
                          _isLastPage ? Icons.check : Icons.arrow_forward,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Skip Button
            if (!_isLastPage)
              Positioned(
                top: 50.h,
                left: 20.w,
                child: TextButton(
                  onPressed: () {
                    _completeAndGoRegister();
                  },
                  child: Text(
                    'تخطي',
                    style: TextStyle(color: Colors.white54, fontSize: 16.sp),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(BuildContext context, OnboardingPageModel page) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 32.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Lottie Animation
          SizedBox(
            height: 300.h,
            width: 300.w,
            child: Lottie.asset(
              page.lottieAsset,
              fit: BoxFit.contain,
              repeat: true,
              animate: true,
            ),
          ),
          SizedBox(height: 48.h),
          Text(
            page.title,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16.h),
          Text(
            page.description,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class OnboardingPageModel {
  final String title;
  final String description;
  final String lottieAsset;
  final Color color;

  OnboardingPageModel({
    required this.title,
    required this.description,
    required this.lottieAsset,
    required this.color,
  });
}
