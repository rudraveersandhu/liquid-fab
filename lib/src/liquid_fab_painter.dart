import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/rendering.dart';

import 'liquid_fab_style.dart';

/// Paints one frame of the liquid ball: a circle whose edge is nudged by the
/// style's travelling waves, drawn in layers (diffused halo, optional
/// shadow, lit radial-gradient surface, hover or press overlay, glossy
/// highlight, illuminated rim).
///
/// Use it on its own with a [CustomPaint] if you want only the drawing and
/// will drive [progress] yourself. The breath is not part of the painting;
/// apply [LiquidFabStyle.breathScaleAt] with a `Transform.scale` if you want
/// it.
class LiquidFabPainter extends CustomPainter {
  /// Creates a painter for one frame.
  LiquidFabPainter({
    required this.progress,
    this.style = const LiquidFabStyle(),
    this.hover = 0,
    this.pressed = false,
    this.padding = 10,
  }) : assert(hover >= 0 && hover <= 1, 'hover must be in [0, 1]'),
       assert(padding >= 0, 'padding must be zero or more'),
       assert(style.debugAssertIsValid());

  /// Position in the animation loop, from 0 to 1. 0 and 1 draw the same
  /// frame.
  final double progress;

  /// What to draw.
  final LiquidFabStyle style;

  /// How hovered the ball is, from 0 (at rest) to 1 (fully hovered). Raises
  /// the halo, lightens the surface and, if a shadow is on, moves it toward
  /// [LiquidFabStyle.hoverElevation].
  final double hover;

  /// Whether the ball is pressed. Darkens the surface with
  /// [LiquidFabStyle.pressOverlayColor]; takes precedence over [hover]'s
  /// overlay.
  final bool pressed;

  /// Room left on each side of the canvas for the halo and the ripple, in
  /// logical pixels. The ball's radius is half the shortest side minus this.
  final double padding;

  /// The edge path for a ball centred at [center] with radius [radius] at
  /// loop [progress], using [style]'s core ratio, waves and point count.
  static Path edgePath(
    LiquidFabStyle style,
    Offset center,
    double radius,
    double progress,
  ) {
    final t = progress * 2 * math.pi;
    final n = style.pointCount;
    final path = Path();
    for (var i = 0; i < n; i++) {
      final angle = i / n * 2 * math.pi;
      var k = style.coreRatio;
      for (final w in style.waves) {
        k += w.offsetAt(angle, t);
      }
      final r = radius * k;
      final x = center.dx + math.cos(angle) * r;
      final y = center.dy + math.sin(angle) * r;
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    return path..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final s = style;
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - padding;
    if (radius <= 0) return;
    final path = edgePath(s, center, radius, progress);

    // 1. Large, diffused halo.
    final haloAlpha = (s.haloOpacity * lerpDouble(1, s.haloHoverBoost, hover)!)
        .clamp(0.0, 1.0);
    if (haloAlpha > 0) {
      canvas.drawPath(
        path,
        Paint()
          ..color = s.effectiveHaloColor.withValues(
            alpha: s.effectiveHaloColor.a * haloAlpha,
          )
          ..maskFilter =
              s.haloBlur > 0
                  ? MaskFilter.blur(BlurStyle.normal, s.haloBlur)
                  : null,
      );
    }

    // 2. Optional floating shadow.
    if (s.showShadow) {
      final elevation = lerpDouble(s.elevation, s.hoverElevation, hover)!;
      if (elevation > 0) {
        canvas.drawShadow(path, s.effectiveShadowColor, elevation, true);
      }
    }

    // 3. The lit surface.
    canvas.drawPath(
      path,
      Paint()
        ..shader = RadialGradient(
          center: s.gradientCenter,
          radius: s.gradientRadius,
          colors: s.colors,
          stops: s.stops,
        ).createShader(Rect.fromCircle(center: center, radius: radius * 1.5)),
    );

    // 4. Hover lightens the surface; a press darkens it.
    final overlay =
        pressed
            ? s.pressOverlayColor.withValues(
              alpha: s.pressOverlayColor.a * s.pressOverlayOpacity,
            )
            : s.hoverOverlayColor.withValues(
              alpha: s.hoverOverlayColor.a * s.hoverOverlayOpacity * hover,
            );
    if (overlay.a > 0) canvas.drawPath(path, Paint()..color = overlay);

    // 5. Glossy highlight: what makes it a sphere rather than a disc.
    if (s.showGloss && s.glossOpacity > 0) {
      final gloss = Rect.fromCenter(
        center: center + s.glossOffset * radius,
        width: radius * s.glossSize.width,
        height: radius * s.glossSize.height,
      );
      if (!gloss.isEmpty) {
        final c = s.glossColor;
        canvas.drawOval(
          gloss,
          Paint()
            ..shader = RadialGradient(
              colors: [
                c.withValues(alpha: c.a * s.glossOpacity),
                c.withValues(alpha: 0),
              ],
            ).createShader(gloss),
        );
      }
    }

    // 6. A thin illuminated rim.
    if (s.rimWidth > 0 && s.rimOpacity > 0) {
      final c = s.effectiveRimColor;
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = s.rimWidth
          ..color = c.withValues(alpha: c.a * s.rimOpacity),
      );
    }
  }

  @override
  bool shouldRepaint(LiquidFabPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.hover != hover ||
      oldDelegate.pressed != pressed ||
      oldDelegate.padding != padding ||
      oldDelegate.style != style;
}
