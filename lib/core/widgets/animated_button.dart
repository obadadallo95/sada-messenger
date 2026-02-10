import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// زر متحرك مع تأثير Scale عند الضغط
/// يدعم Haptic Feedback
class AnimatedButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final ButtonStyle? style;
  final bool isOutlined;

  const AnimatedButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.style,
    this.isOutlined = false,
  });

  @override
  State<AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
    HapticFeedback.lightImpact();
    widget.onPressed?.call();
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final button = widget.isOutlined
        ? OutlinedButton(
            onPressed: widget.onPressed,
            style: widget.style,
            child: widget.child,
          )
        : ElevatedButton(
            onPressed: widget.onPressed,
            style: widget.style,
            child: widget.child,
          );

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: button,
      ),
    );
  }
}

