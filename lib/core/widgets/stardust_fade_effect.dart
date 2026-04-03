import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

class StardustFadeEffect extends StatefulWidget {
  final Widget child;
  final bool isTriggered;
  final VoidCallback? onCaptureComplete;
  final VoidCallback? onAnimationComplete;

  const StardustFadeEffect({
    super.key,
    required this.child,
    required this.isTriggered,
    this.onCaptureComplete,
    this.onAnimationComplete,
  });

  @override
  State<StardustFadeEffect> createState() => _StardustFadeEffectState();
}

class _StardustFadeEffectState extends State<StardustFadeEffect>
    with SingleTickerProviderStateMixin {
  final GlobalKey _globalKey = GlobalKey();
  late AnimationController _controller;
  List<Particle>? _particles;
  bool _isAnimating = false;
  ui.Image? _snapshotImage;

  @override
  void initState() {
    super.initState();
    // 0.3s hold + 0.8s scatter
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _isAnimating = false;
          _particles = null;
          _snapshotImage?.dispose();
          _snapshotImage = null;
        });
        widget.onAnimationComplete?.call();
      }
    });
  }

  @override
  void didUpdateWidget(covariant StardustFadeEffect oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isTriggered && !oldWidget.isTriggered && !_isAnimating) {
      _startEffect();
    }
  }

  Future<void> _startEffect() async {
    try {
      final boundary = _globalKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 1.0);
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.rawRgba);

      if (byteData == null) return;

      _particles = await _generateParticles(byteData, image.width, image.height);
      _snapshotImage = image;

      setState(() {
        _isAnimating = true;
      });
      
      // Notify parent that capture is done (e.g. to clear the text field underneath)
      widget.onCaptureComplete?.call();

      _controller.forward(from: 0);
    } catch (e) {
      debugPrint('Stardust effect error: $e');
    }
  }

  // Running particle generation in an isolate could be better for large images,
  // but for simple text, async on main thread might be acceptable. 
  Future<List<Particle>> _generateParticles(
      ByteData byteData, int width, int height) async {
    final List<Particle> particles = [];
    final random = Random();

    // Downsample step to save performance
    // A step of 2 gives good particle density for text
    const int step = 2;

    for (int y = 0; y < height; y += step) {
      for (int x = 0; x < width; x += step) {
        final offset = (y * width + x) * 4;
        // R G B A
        final a = byteData.getUint8(offset + 3);

        if (a > 20) { // If pixel is not highly transparent
          final angle = random.nextDouble() * 2 * pi;
          // Particles move primarily upward for a "burning/smoke" effect
          final speedY = random.nextDouble() * 2.0 + 1.0; // Upward speed
          final speedX = (random.nextDouble() - 0.5) * 1.5; // Slight horizontal drift
          
          // Add a delay based on Y coordinate to make it burn from top to bottom, 
          // or add random delay for uneven burning
          final delay = random.nextDouble() * 0.3 + (y / height) * 0.4;
          
          // Burning colors: mix of bright yellow, orange, and dark red/gray
          Color particleColor;
          final colorType = random.nextDouble();
          if (colorType > 0.8) {
            particleColor = const Color(0xFFFFD700); // Bright Yellow/Gold
          } else if (colorType > 0.4) {
            particleColor = const Color(0xFFFF8C00); // Orange
          } else if (colorType > 0.1) {
            particleColor = const Color(0xFFFF4500); // Dark Orange/Red
          } else {
            particleColor = const Color(0xFF4A4A4A); // Ash/Smoke
          }

          particles.add(Particle(
            x: x.toDouble(),
            y: y.toDouble(),
            dx: speedX,
            dy: -speedY, // Negative Y means moving up
            color: particleColor.withOpacity(a / 255.0),
            delay: delay,
          ));
        }
      }
    }
    return particles;
  }

  @override
  void dispose() {
    _controller.dispose();
    _snapshotImage?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Always render the child (which may be cleared after capture), but wrap in boundary
        RepaintBoundary(
          key: _globalKey,
          child: widget.child,
        ),
        
        // Render the animation on top when triggered
        if (_isAnimating)
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                // 0.3s hold = 300 / 1100 = ~0.27
                final progressValue = _controller.value;
                final threshold = 300 / 1100;
                
                double progress = 0.0;
                if (progressValue > threshold) {
                  progress = (progressValue - threshold) / (1.0 - threshold);
                }

                return CustomPaint(
                  size: Size(
                    _snapshotImage?.width.toDouble() ?? 0,
                    _snapshotImage?.height.toDouble() ?? 0,
                  ),
                  painter: StardustPainter(
                    particles: _particles,
                    progress: progress,
                    isHolding: progress == 0.0,
                    originalImage: _snapshotImage,
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class Particle {
  final double x;
  final double y;
  final double dx;
  final double dy;
  final Color color;
  final double delay;

  Particle({
    required this.x,
    required this.y,
    required this.dx,
    required this.dy,
    required this.color,
    required this.delay,
  });
}

class StardustPainter extends CustomPainter {
  final List<Particle>? particles;
  final double progress; // 0.0 to 1.0 (scatter progress)
  final bool isHolding;
  final ui.Image? originalImage;

  StardustPainter({
    this.particles,
    required this.progress,
    required this.isHolding,
    this.originalImage,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (isHolding && originalImage != null) {
      canvas.drawImage(originalImage!, Offset.zero, Paint());
      return;
    }

    if (particles == null) return;

    final paint = Paint()..style = PaintingStyle.fill;

    for (var particle in particles!) {
      // Calculate local progress for each particle based on its delay
      // The duration of each particle's animation is 1.0 - delay
      double localProgress = 0.0;
      if (progress > particle.delay) {
        localProgress = (progress - particle.delay) / (1.0 - particle.delay);
        localProgress = localProgress.clamp(0.0, 1.0);
      }

      // If particle hasn't started moving yet, just draw it at its original position
      if (localProgress <= 0.0) {
        paint.color = particle.color;
        canvas.drawCircle(Offset(particle.x, particle.y), 1.0, paint);
        continue;
      }

      // Movement
      final currentX = particle.x + particle.dx * localProgress * 50; 
      // Upward motion with some gravity/acceleration
      final currentY = particle.y + particle.dy * localProgress * 80 - (localProgress * localProgress) * 20; 

      // Fade out towards the end of its local progress
      final opacity = (1.0 - localProgress).clamp(0.0, 1.0);
      
      // As it burns, it gets smaller and fades out
      final size = (1.0 - localProgress * 0.8).clamp(0.1, 1.0);
      
      paint.color = particle.color.withOpacity(particle.color.opacity * opacity);

      // Draw the particle
      canvas.drawCircle(Offset(currentX, currentY), size * 1.5, paint);
    }
  }

  @override
  bool shouldRepaint(covariant StardustPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.isHolding != isHolding;
  }
}
