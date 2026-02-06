import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../../../core/router/routes.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/repositories/onboarding_repository.dart';
import '../widgets/onboarding_slide.dart';

/// شاشة Onboarding مع 3 slides
/// تشرح ميزات التطبيق الفريدة للمستخدم
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
    });
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  Future<void> _completeOnboarding() async {
    try {
      await ref.read(onboardingRepositoryProvider.notifier).completeOnboarding();
      if (mounted) {
        context.go(AppRoutes.home);
      }
    } catch (e) {
      // في حالة الخطأ، الانتقال إلى Home على أي حال
      if (mounted) {
        context.go(AppRoutes.home);
      }
    }
  }

  void _skipOnboarding() {
    _completeOnboarding();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isLastPage = _currentPage == 2;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // زر Skip (أعلى اليمين)
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 24.w,
                vertical: 16.h,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _skipOnboarding,
                    child: Text(
                      l10n.skip,
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // PageView مع Slides
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: 3,
                itemBuilder: (context, index) {
                  return _buildSlide(context, l10n, index);
                },
              ),
            ),

            // Page Indicator (النقاط)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 24.h),
              child: SmoothPageIndicator(
                controller: _pageController,
                count: 3,
                effect: WormEffect(
                  activeDotColor: Theme.of(context).colorScheme.primary,
                  dotColor: Theme.of(context).colorScheme.primaryContainer,
                  dotHeight: 8.h,
                  dotWidth: 8.w,
                  spacing: 8.w,
                ),
              ),
            ),

            // زر Next / Get Started
            Padding(
              padding: EdgeInsets.fromLTRB(24.w, 0, 24.w, 32.h),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _nextPage,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: Text(
                    isLastPage ? l10n.getStarted : l10n.next,
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlide(BuildContext context, AppLocalizations l10n, int index) {
    switch (index) {
      case 0:
        return OnboardingSlide(
          icon: Icons.signal_wifi_off,
          title: l10n.onboardingSlide1Title,
          description: l10n.onboardingSlide1Description,
        );
      case 1:
        return OnboardingSlide(
          icon: Icons.security,
          title: l10n.onboardingSlide2Title,
          description: l10n.onboardingSlide2Description,
        );
      case 2:
        return OnboardingSlide(
          icon: Icons.people,
          title: l10n.onboardingSlide3Title,
          description: l10n.onboardingSlide3Description,
        );
      default:
        return const SizedBox();
    }
  }
}

