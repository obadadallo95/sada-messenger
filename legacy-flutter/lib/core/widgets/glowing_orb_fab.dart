import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Glowing Orb FAB Widget
/// Cyber-Stealth aesthetic with continuous pulse animation
class GlowingOrbFAB extends StatefulWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final Color? glowColor;

  const GlowingOrbFAB({
    super.key,
    required this.onPressed,
    required this.icon,
    this.glowColor,
  });

  @override
  State<GlowingOrbFAB> createState() => _GlowingOrbFABState();
}

class _GlowingOrbFABState extends State<GlowingOrbFAB>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final glowColor = widget.glowColor ?? theme.colorScheme.primary;

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Outer glow rings (pulsing)
            ...List.generate(3, (index) {
              final delay = index * 0.3;
              final animationValue = (_pulseController.value + delay) % 1.0;
              final scale = 1.0 + (animationValue * 0.5);
              final opacity = (1.0 - animationValue) * 0.3;

              return Transform.scale(
                scale: scale,
                child: Container(
                  width: 64.w,
                  height: 64.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: glowColor.withValues(alpha: opacity),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                ),
              );
            }),
            // Main FAB
            FloatingActionButton(
              onPressed: widget.onPressed,
              backgroundColor: glowColor,
              elevation: 0,
              child: Icon(
                widget.icon,
                color: Colors.black,
                size: 24.sp,
              ),
            ),
          ],
        );
      },
    );
  }
}

