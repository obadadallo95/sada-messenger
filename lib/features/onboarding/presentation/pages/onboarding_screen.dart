import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../../../core/widgets/mesh_gradient_background.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  bool _isLastPage = false;

  final List<OnboardingPageModel> _pages = [
    OnboardingPageModel(
      title: 'خارج الشبكة؟ لا مشكلة.',
      description: 'صدى يعمل بدون إنترنت أو أبراج اتصال. نستخدم تقنية Mesh لربط الهواتف ببعضها مباشرة.',
      icon: Icons.wifi_off_rounded,
      color: Colors.cyanAccent,
    ),
    OnboardingPageModel(
      title: 'أنت جزء من الشبكة',
      description: 'هاتفك يعمل كساعي بريد مشفر. الرسائل تنتقل من هاتف لآخر حتى تصل لهدفها.',
      icon: Icons.hub_rounded,
      color: Colors.purpleAccent,
    ),
    OnboardingPageModel(
      title: 'مشفرة وآمنة تماماً',
      description: 'لا سيرفرات، لا تتبع. الرسائل مشفرة ولا يمكن لأحد قراءتها غير المستلم الحقيقي.',
      icon: Icons.security_rounded,
      color: Colors.greenAccent,
    ),
    OnboardingPageModel(
      title: 'قد يستغرق وقتاً',
      description: 'لأننا نعتمد على حركة الناس، وصول الرسالة قد يتأخر قليلاً. الصبر مفتاح الأمان.',
      icon: Icons.hourglass_bottom_rounded,
      color: Colors.amberAccent,
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
              child: Row(
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
                        // TODO: Navigate to Auth/Main
                        // Navigator.pushReplacementNamed(context, '/auth');
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('مرحباً بك في صدى')),
                        );
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
                    child: Icon(_isLastPage ? Icons.check : Icons.arrow_forward),
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
                    _controller.jumpToPage(_pages.length - 1);
                  },
                  child: Text(
                    'تخطي',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 16.sp,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(BuildContext context, OnboardingPageModel page) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 32.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(40.w),
            decoration: BoxDecoration(
              color: page.color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: page.color.withValues(alpha: 0.2),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Icon(
              page.icon,
              size: 80.sp,
              color: page.color,
            ),
          ),
          SizedBox(height: 48.h),
          Text(
            page.title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16.h),
          Text(
            page.description,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white70,
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
  final IconData icon;
  final Color color;

  OnboardingPageModel({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}
