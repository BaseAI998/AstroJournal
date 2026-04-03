import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class BurnFadeEffect extends StatefulWidget {
  final Widget child;
  final bool isTriggered;
  final VoidCallback? onCaptureComplete;
  final VoidCallback? onAnimationComplete;

  const BurnFadeEffect({
    super.key,
    required this.child,
    required this.isTriggered,
    this.onCaptureComplete,
    this.onAnimationComplete,
  });

  @override
  State<BurnFadeEffect> createState() => _BurnFadeEffectState();
}

class _BurnFadeEffectState extends State<BurnFadeEffect>
    with SingleTickerProviderStateMixin {
  final GlobalKey _globalKey = GlobalKey();
  late AnimationController _controller;
  bool _isAnimating = false;
  ui.Image? _snapshotImage;
  ui.FragmentProgram? _program;

  @override
  void initState() {
    super.initState();
    _loadShader();

    // 0.3s hold + 1.2s burn
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _isAnimating = false;
          _snapshotImage?.dispose();
          _snapshotImage = null;
        });
        widget.onAnimationComplete?.call();
      }
    });
  }

  Future<void> _loadShader() async {
    try {
      _program = await ui.FragmentProgram.fromAsset('shaders/burn.frag');
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Failed to load burn shader: $e');
    }
  }

  @override
  void didUpdateWidget(covariant BurnFadeEffect oldWidget) {
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

      // Capture the high-res image
      final image = await boundary.toImage(pixelRatio: MediaQuery.of(context).devicePixelRatio);
      _snapshotImage = image;

      setState(() {
        _isAnimating = true;
      });
      
      // Notify parent that capture is done (e.g. to clear the text field underneath)
      widget.onCaptureComplete?.call();

      _controller.forward(from: 0);
    } catch (e) {
      debugPrint('Burn effect error: $e');
    }
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
        
        // Render the shader animation on top when triggered
        if (_isAnimating && _snapshotImage != null && _program != null)
          Positioned(
            left: 0,
            top: 0,
            child: Transform.scale(
              scale: 1.0 / MediaQuery.of(context).devicePixelRatio,
              alignment: Alignment.topLeft,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  // 0.3s hold = 300 / 1500 = 0.2
                  final progressValue = _controller.value;
                  const threshold = 0.2;
                  
                  double burnProgress = 0.0;
                  if (progressValue > threshold) {
                    burnProgress = (progressValue - threshold) / (1.0 - threshold);
                  }

                  return CustomPaint(
                    size: Size(
                      _snapshotImage!.width.toDouble(),
                      _snapshotImage!.height.toDouble(),
                    ),
                    painter: BurnPainter(
                      shaderProgram: _program!,
                      image: _snapshotImage!,
                      progress: burnProgress,
                      isHolding: burnProgress == 0.0,
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}

class BurnPainter extends CustomPainter {
  final ui.FragmentProgram shaderProgram;
  final ui.Image image;
  final double progress; // 0.0 to 1.0 (burn progress)
  final bool isHolding;

  BurnPainter({
    required this.shaderProgram,
    required this.image,
    required this.progress,
    required this.isHolding,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (isHolding) {
      // Just draw the original image during the hold phase
      canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint(),
      );
      return;
    }

    final shader = shaderProgram.fragmentShader();
    
    // Set uniforms
    // 0: vec2 resolution
    // 1: float progress
    shader.setFloat(0, image.width.toDouble());
    shader.setFloat(1, image.height.toDouble());
    shader.setFloat(2, progress);
    
    // Sampler (Texture)
    shader.setImageSampler(0, image);

    final paint = Paint()..shader = shader;
    
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant BurnPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.isHolding != isHolding;
  }
}