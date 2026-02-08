import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sada/l10n/generated/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../../../core/router/routes.dart';
import '../../data/repositories/onboarding_repository.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  List<OnboardingSlide> get _slides {
    final l10n = AppLocalizations.of(context)!;
    return [
      OnboardingSlide(
        title: l10n.noInternetNoProblem,
        description: l10n.noInternetDescription,
        lottieAsset: 'assets/json/Global Network.json',
      ),
      OnboardingSlide(
        title: l10n.youAreTheNetwork,
        description: l10n.youAreTheNetworkDescription,
        lottieAsset: 'assets/json/Global Network.json',
        isReusedAsset: true,
      ),
      OnboardingSlide(
        title: l10n.invisibleAndSecure,
        description: l10n.invisibleAndSecureDescription,
        lottieAsset: 'assets/json/data security.json',
      ),
      OnboardingSlide(
        title: l10n.readyToConnect,
        description: l10n.readyToConnectDescription,
        lottieAsset: 'assets/json/404 error page with cat.json',
        isPermissionSlide: true,
      ),
    ];
  }

  Future<void> _completeOnboarding() async {
    await ref.read(onboardingRepositoryProvider.notifier).completeOnboarding();
    if (mounted) {
      context.go(AppRoutes.register);
    }
  }

  Future<void> _requestPermissions() async {
    await [
      Permission.location,
      Permission.nearbyWifiDevices,
      Permission.notification,
    ].request();

    if (mounted) {
      _completeOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final slides = _slides;
    
    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient (Cyberpunk)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF050A14), // Deep Midnight Blue
                  const Color.fromARGB(255, 6, 28, 40), // Darker Teal/Blue
                ],
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                // Skip Button
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _completeOnboarding,
                    child: Text(
                      l10n.skip,
                      style: TextStyle(
                        color: theme.colorScheme.primary.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ),
                
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    itemCount: slides.length,
                    itemBuilder: (context, index) {
                      return _buildSlide(slides[index], theme);
                    },
                  ),
                ),
                
                // Bottom Section: Indicator & Buttons
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SmoothPageIndicator(
                        controller: _pageController,
                        count: slides.length,
                        effect: ExpandingDotsEffect(
                          activeDotColor: theme.colorScheme.primary,
                          dotColor: theme.colorScheme.surfaceContainerHighest,
                          dotHeight: 8.h,
                          dotWidth: 8.w,
                          spacing: 4,
                        ),
                      ),
                      
                      FloatingActionButton(
                        onPressed: () {
                          if (_currentPage == slides.length - 1) {
                            if (slides[_currentPage].isPermissionSlide) {
                              _requestPermissions();
                            } else {
                              _completeOnboarding();
                            }
                          } else {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                        },
                        backgroundColor: theme.colorScheme.primary,
                        child: Icon(
                          _currentPage == slides.length - 1 
                              ? Icons.check 
                              : Icons.arrow_forward,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlide(OnboardingSlide slide, ThemeData theme) {
    return Padding(
      padding: EdgeInsets.all(24.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            flex: 3,
            child: SizedBox(
              child: Lottie.asset(
                slide.lottieAsset,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.image_not_supported,
                    size: 100.sp,
                    color: theme.colorScheme.error,
                  );
                },
              ),
            )
            .animate()
            .fadeIn(duration: 600.ms)
            .scale(delay: 200.ms),
          ),
          
          SizedBox(height: 32.h),
          
          Text(
            slide.title,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
              height: 1.2,
            ),
          )
          .animate()
          .fadeIn(delay: 300.ms, duration: 600.ms)
          .moveY(begin: 20, end: 0),
          
          SizedBox(height: 16.h),
          
          Text(
            slide.description,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
              height: 1.5,
            ),
          )
          .animate()
          .fadeIn(delay: 500.ms, duration: 600.ms)
          .moveY(begin: 20, end: 0),
          
          if (slide.isPermissionSlide) ...[
            SizedBox(height: 32.h),
            _buildPermissionBadges(theme),
          ],
        ],
      ),
    );
  }
  
  Widget _buildPermissionBadges(ThemeData theme) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _PermissionBadge(icon: Icons.location_on, label: l10n.permissionLocation),
        SizedBox(width: 16.w),
        _PermissionBadge(icon: Icons.notifications, label: l10n.permissionNotify),
        SizedBox(width: 16.w),
        _PermissionBadge(icon: Icons.wifi, label: l10n.permissionWifi),
      ],
    ).animate().fadeIn(delay: 800.ms).scale();
  }
}

class _PermissionBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _PermissionBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            shape: BoxShape.circle,
            border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
          ),
          child: Icon(icon, color: theme.colorScheme.primary, size: 24.sp),
        ),
        SizedBox(height: 8.h),
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}

class OnboardingSlide {
  final String title;
  final String description;
  final String lottieAsset;
  final bool isPermissionSlide;
  final bool isReusedAsset;

  OnboardingSlide({
    required this.title,
    required this.description,
    required this.lottieAsset,
    this.isPermissionSlide = false,
    this.isReusedAsset = false,
  });
}
