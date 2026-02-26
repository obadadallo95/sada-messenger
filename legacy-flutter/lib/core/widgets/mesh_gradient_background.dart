import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Mesh Gradient Background Widget
/// Creates a "living" background with slowly moving color blobs
/// Cyber-Stealth aesthetic: Electric Cyan and Neon Purple
class MeshGradientBackground extends StatefulWidget {
  final Widget child;

  const MeshGradientBackground({
    super.key,
    required this.child,
  });

  @override
  State<MeshGradientBackground> createState() => _MeshGradientBackgroundState();
}

class _MeshGradientBackgroundState extends State<MeshGradientBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final math.Random _random = math.Random();

  // Blob positions and sizes (animated)
  late List<BlobData> _blobs;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20), // Slow, smooth movement
    )..repeat();

    // Initialize blobs with random positions
    _blobs = List.generate(4, (index) => BlobData.random(_random));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Update blob positions based on animation
        for (var blob in _blobs) {
          blob.update(_controller.value);
        }

        return CustomPaint(
          painter: MeshGradientPainter(_blobs),
          child: widget.child,
        );
      },
    );
  }
}

/// Blob data for mesh gradient
class BlobData {
  double x;
  double y;
  double size;
  double speedX;
  double speedY;
  Color color;
  double baseX;
  double baseY;

  BlobData({
    required this.x,
    required this.y,
    required this.size,
    required this.speedX,
    required this.speedY,
    required this.color,
    required this.baseX,
    required this.baseY,
  });

  factory BlobData.random(math.Random random) {
    final colors = [
      const Color(0xFF00E5FF).withValues(alpha: 0.15), // Electric Cyan
      const Color(0xFFD500F9).withValues(alpha: 0.15), // Neon Purple
    ];
    
    return BlobData(
      x: random.nextDouble(),
      y: random.nextDouble(),
      size: 200 + random.nextDouble() * 300,
      speedX: (random.nextDouble() - 0.5) * 0.3,
      speedY: (random.nextDouble() - 0.5) * 0.3,
      color: colors[random.nextInt(colors.length)],
      baseX: random.nextDouble(),
      baseY: random.nextDouble(),
    );
  }

  void update(double animationValue) {
    // Smooth circular motion
    x = baseX + math.sin(animationValue * 2 * math.pi + speedX) * 0.2;
    y = baseY + math.cos(animationValue * 2 * math.pi + speedY) * 0.2;
  }
}

/// Custom painter for mesh gradient
class MeshGradientPainter extends CustomPainter {
  final List<BlobData> blobs;

  MeshGradientPainter(this.blobs);

  @override
  void paint(Canvas canvas, Size size) {
    for (var blob in blobs) {
      final paint = Paint()
        ..color = blob.color
        ..style = PaintingStyle.fill;

      // Create radial gradient for each blob
      final gradient = RadialGradient(
        colors: [
          blob.color,
          blob.color.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 1.0],
      );

      final rect = Rect.fromCircle(
        center: Offset(
          blob.x * size.width,
          blob.y * size.height,
        ),
        radius: blob.size,
      );

      final shader = gradient.createShader(rect);
      paint.shader = shader;

      canvas.drawCircle(
        Offset(blob.x * size.width, blob.y * size.height),
        blob.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(MeshGradientPainter oldDelegate) {
    return true; // Always repaint for smooth animation
  }
}

