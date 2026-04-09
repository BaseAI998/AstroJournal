import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../model/chart_data.dart';

/// Draws an astrological chart disc:
/// - Outer ring: 12 zodiac signs with glyphs
/// - Middle ring: house divisions
/// - Inner area: planet glyphs at their angular positions
class ChartDiscPainter extends CustomPainter {
  final ChartData data;

  ChartDiscPainter({required this.data});

  static const _signGlyphs = [
    '\u2648', '\u2649', '\u264A', '\u264B', '\u264C', '\u264D',
    '\u264E', '\u264F', '\u2650', '\u2651', '\u2652', '\u2653',
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 8;

    final outerR = radius;
    final signR = radius * 0.85;
    final innerR = radius * 0.70;
    final planetR = radius * 0.50;
    final coreR = radius * 0.20;

    // Ascendant offset: rotate the whole chart so ASC is at 9 o'clock (left)
    final ascOffset = -data.ascendantDegree * pi / 180 + pi;

    _drawOuterRing(canvas, center, outerR, signR, ascOffset);
    _drawSignGlyphs(canvas, center, outerR, signR, ascOffset);
    _drawInnerCircle(canvas, center, innerR);
    _drawHouseLines(canvas, center, innerR, signR, ascOffset);
    _drawCoreCircle(canvas, center, coreR);
    _drawPlanets(canvas, center, planetR, innerR, ascOffset);
    _drawAscArrow(canvas, center, innerR, outerR, ascOffset);
  }

  void _drawOuterRing(Canvas canvas, Offset center, double outerR,
      double signR, double ascOffset) {
    // Outer circle
    final outerPaint = Paint()
      ..color = AppTheme.accentSepia.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, outerR, outerPaint);
    canvas.drawCircle(center, signR, outerPaint);

    // 12 sign division lines
    final divPaint = Paint()
      ..color = AppTheme.accentSepia.withOpacity(0.35)
      ..strokeWidth = 0.8;

    for (int i = 0; i < 12; i++) {
      final angle = ascOffset + i * pi / 6;
      final from = Offset(
        center.dx + signR * cos(angle),
        center.dy + signR * sin(angle),
      );
      final to = Offset(
        center.dx + outerR * cos(angle),
        center.dy + outerR * sin(angle),
      );
      canvas.drawLine(from, to, divPaint);
    }
  }

  void _drawSignGlyphs(Canvas canvas, Offset center, double outerR,
      double signR, double ascOffset) {
    final glyphR = (outerR + signR) / 2;

    for (int i = 0; i < 12; i++) {
      // Center of each 30° segment
      final angle = ascOffset + (i * 30 + 15) * pi / 180;
      final pos = Offset(
        center.dx + glyphR * cos(angle),
        center.dy + glyphR * sin(angle),
      );

      final textPainter = TextPainter(
        text: TextSpan(
          text: _signGlyphs[i],
          style: TextStyle(
            fontSize: outerR * 0.09,
            color: AppTheme.accentSepia.withOpacity(0.7),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(
        canvas,
        Offset(pos.dx - textPainter.width / 2, pos.dy - textPainter.height / 2),
      );
    }
  }

  void _drawInnerCircle(Canvas canvas, Offset center, double innerR) {
    final paint = Paint()
      ..color = AppTheme.accentSepia.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, innerR, paint);
  }

  void _drawHouseLines(Canvas canvas, Offset center, double innerR,
      double signR, double ascOffset) {
    final paint = Paint()
      ..color = AppTheme.border.withOpacity(0.5)
      ..strokeWidth = 0.5;

    // Simple equal-house: 12 divisions from ASC
    for (int i = 0; i < 12; i++) {
      final angle = ascOffset + i * pi / 6;
      final from = center;
      final to = Offset(
        center.dx + innerR * cos(angle),
        center.dy + innerR * sin(angle),
      );
      canvas.drawLine(from, to, paint);
    }
  }

  void _drawCoreCircle(Canvas canvas, Offset center, double coreR) {
    final fill = Paint()
      ..color = AppTheme.panel.withOpacity(0.5)
      ..style = PaintingStyle.fill;
    final stroke = Paint()
      ..color = AppTheme.accentSepia.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    canvas.drawCircle(center, coreR, fill);
    canvas.drawCircle(center, coreR, stroke);
  }

  void _drawPlanets(Canvas canvas, Offset center, double planetR,
      double innerR, double ascOffset) {
    // Collect angles, then spread overlapping ones
    final items = <_PlacedPlanet>[];
    for (final p in data.planets) {
      final angle = ascOffset + p.absDegree * pi / 180;
      items.add(_PlacedPlanet(p, angle));
    }

    // Simple collision avoidance: sort by angle, push apart if too close
    items.sort((a, b) => a.angle.compareTo(b.angle));
    const minGap = 0.18; // ~10 degrees
    for (int pass = 0; pass < 3; pass++) {
      for (int i = 0; i < items.length; i++) {
        final next = (i + 1) % items.length;
        var diff = items[next].angle - items[i].angle;
        if (diff < 0) diff += 2 * pi;
        if (diff < minGap) {
          final push = (minGap - diff) / 2;
          items[i].angle -= push;
          items[next].angle += push;
        }
      }
    }

    for (final item in items) {
      final r = planetR;
      final pos = Offset(
        center.dx + r * cos(item.angle),
        center.dy + r * sin(item.angle),
      );

      // Glyph
      final glyph = item.planet.planetGlyph;
      final color = item.planet.retrograde
          ? AppTheme.danger
          : AppTheme.accentGold;

      final tp = TextPainter(
        text: TextSpan(
          text: glyph,
          style: TextStyle(
            fontSize: innerR * 0.16,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(pos.dx - tp.width / 2, pos.dy - tp.height / 2),
      );

      // Degree text
      final degTp = TextPainter(
        text: TextSpan(
          text: '${item.planet.degree.toStringAsFixed(0)}°',
          style: TextStyle(
            fontSize: innerR * 0.07,
            color: AppTheme.textSecondary.withOpacity(0.7),
            fontFamily: 'serif',
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      degTp.paint(
        canvas,
        Offset(pos.dx - degTp.width / 2, pos.dy + tp.height / 2),
      );
    }
  }

  void _drawAscArrow(Canvas canvas, Offset center, double innerR,
      double outerR, double ascOffset) {
    // Small arrow at ASC position (left side)
    final angle = ascOffset;
    final tipR = outerR + 6;
    final tip = Offset(
      center.dx + tipR * cos(angle),
      center.dy + tipR * sin(angle),
    );

    final paint = Paint()
      ..color = AppTheme.accentGold
      ..style = PaintingStyle.fill;

    final arrowSize = 6.0;
    final perpAngle = angle + pi / 2;
    final path = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(
        tip.dx - arrowSize * cos(angle) + arrowSize * 0.5 * cos(perpAngle),
        tip.dy - arrowSize * sin(angle) + arrowSize * 0.5 * sin(perpAngle),
      )
      ..lineTo(
        tip.dx - arrowSize * cos(angle) - arrowSize * 0.5 * cos(perpAngle),
        tip.dy - arrowSize * sin(angle) - arrowSize * 0.5 * sin(perpAngle),
      )
      ..close();
    canvas.drawPath(path, paint);

    // "ASC" label
    final tp = TextPainter(
      text: const TextSpan(
        text: 'ASC',
        style: TextStyle(
          fontSize: 9,
          color: AppTheme.accentGold,
          fontFamily: 'serif',
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset(tip.dx - tp.width / 2 - 14 * cos(angle),
          tip.dy - tp.height / 2 - 14 * sin(angle)),
    );
  }

  @override
  bool shouldRepaint(ChartDiscPainter oldDelegate) {
    return oldDelegate.data != data;
  }
}

class _PlacedPlanet {
  final PlanetPosition planet;
  double angle;
  _PlacedPlanet(this.planet, this.angle);
}
