import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// Paints the organic vine stem that runs vertically through the timeline.
///
/// The vine is drawn as a series of cubic bezier curves that gently sway
/// left and right. Small tendrils branch off at each node position.
class VinePainter extends CustomPainter {
  /// Y-positions where journal nodes sit (in local coordinates).
  final List<double> nodeYPositions;

  /// Whether each node sits on the left (true) or right (false) side.
  final List<bool> nodeIsLeft;

  /// Set of indices whose nodes belong to the active origin map.
  final Set<int> highlightedIndices;

  /// Total height of the paint area.
  final double totalHeight;

  /// Whether the vine is in collapsed (narrow) mode.
  final bool collapsed;

  VinePainter({
    required this.nodeYPositions,
    required this.nodeIsLeft,
    required this.highlightedIndices,
    required this.totalHeight,
    this.collapsed = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final vinePaint = Paint()
      ..color = AppTheme.accentSepia.withOpacity(0.6)
      ..strokeWidth = collapsed ? 2.0 : 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final tendrilPaint = Paint()
      ..color = AppTheme.accentSepia.withOpacity(0.35)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final glowPaint = Paint()
      ..color = AppTheme.accentGold.withOpacity(0.3)
      ..strokeWidth = 6.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    // Draw the main vine stem as gentle S-curves
    final vinePath = Path();
    final amplitude = collapsed ? 6.0 : 14.0;
    final segmentHeight = 60.0;
    final segments = (totalHeight / segmentHeight).ceil() + 1;

    vinePath.moveTo(centerX, 0);
    for (int i = 0; i < segments; i++) {
      final y0 = i * segmentHeight;
      final y1 = (i + 1) * segmentHeight;
      final yMid = (y0 + y1) / 2;
      final dir = (i % 2 == 0) ? 1.0 : -1.0;
      vinePath.cubicTo(
        centerX + amplitude * dir, yMid - segmentHeight * 0.15,
        centerX - amplitude * dir, yMid + segmentHeight * 0.15,
        centerX, y1,
      );
    }
    canvas.drawPath(vinePath, vinePaint);

    // Draw tendrils to each node
    for (int i = 0; i < nodeYPositions.length; i++) {
      final nodeY = nodeYPositions[i];
      final isLeft = nodeIsLeft[i];
      final isHighlighted = highlightedIndices.contains(i);

      // Tendril endpoint: where the node card connects
      final tendrilEndX = isLeft
          ? (collapsed ? centerX - 16 : centerX - 50)
          : (collapsed ? centerX + 16 : centerX + 50);

      // Calculate where the vine stem is at this Y position
      final segIndex = nodeY / segmentHeight;
      final frac = segIndex - segIndex.floor();
      // Approximate x on the sine wave
      final dir = (segIndex.floor() % 2 == 0) ? 1.0 : -1.0;
      final stemX = centerX + amplitude * dir * sin(frac * pi);

      final tendrilPath = Path();
      tendrilPath.moveTo(stemX, nodeY);

      // A small organic curl
      final cpX = isLeft ? stemX - 15 : stemX + 15;
      final cpY = nodeY - 8;
      tendrilPath.quadraticBezierTo(cpX, cpY, tendrilEndX, nodeY);

      if (isHighlighted) {
        canvas.drawPath(tendrilPath, glowPaint);
      }
      canvas.drawPath(tendrilPath, tendrilPaint);

      // Small leaf/bud at the connection point on the stem
      final budPaint = Paint()
        ..color = isHighlighted
            ? AppTheme.accentGold.withOpacity(0.7)
            : AppTheme.accentSepia.withOpacity(0.4)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(stemX, nodeY), collapsed ? 3 : 4, budPaint);
    }
  }

  @override
  bool shouldRepaint(VinePainter oldDelegate) {
    return oldDelegate.nodeYPositions != nodeYPositions ||
        oldDelegate.highlightedIndices != highlightedIndices ||
        oldDelegate.totalHeight != totalHeight ||
        oldDelegate.collapsed != collapsed;
  }
}
