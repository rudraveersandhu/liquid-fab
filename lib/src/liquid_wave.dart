import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';

/// One travelling sine wave that nudges the edge of a [LiquidFab] in and out.
///
/// The edge radius at angle `θ` and loop phase `t` (0 to 2π) is
///
/// ```text
/// r(θ, t) = radius * (coreRatio + Σ depth * sin(lobes * θ + speed * t + phase))
/// ```
///
/// [speed] is an integer, so every wave completes a whole number of cycles
/// per loop and the animation repeats without a visible seam.
@immutable
class LiquidWave {
  /// Creates a wave spec.
  const LiquidWave({
    required this.lobes,
    required this.depth,
    this.speed = 1,
    this.phase = 0,
  }) : assert(lobes >= 0, 'lobes must be zero or more'),
       assert(depth >= 0 && depth <= 0.5, 'depth must be in [0, 0.5]');

  /// How many bumps the wave puts around the edge. `0` makes the whole ball
  /// pulse in and out; `2` squashes it into an oval; `3` and up read as
  /// liquid.
  final int lobes;

  /// Peak displacement as a fraction of the ball's radius. The edge moves by
  /// twice this from crest to trough, so keep it small: `0.01` is already
  /// visible on a 60px ball.
  final double depth;

  /// Whole cycles the wave travels per animation loop. Positive values travel
  /// clockwise, negative values counter-clockwise, `0` holds the wave still.
  final int speed;

  /// Starting phase offset, in radians.
  final double phase;

  /// The wave's displacement (as a fraction of the radius) at edge angle
  /// [angle] and loop phase [t], both in radians.
  double offsetAt(double angle, double t) =>
      depth * math.sin(lobes * angle + speed * t + phase);

  /// Returns a copy with the given fields replaced.
  LiquidWave copyWith({int? lobes, double? depth, int? speed, double? phase}) =>
      LiquidWave(
        lobes: lobes ?? this.lobes,
        depth: depth ?? this.depth,
        speed: speed ?? this.speed,
        phase: phase ?? this.phase,
      );

  /// Returns a copy with [depth] multiplied by [factor].
  LiquidWave scaled(double factor) =>
      copyWith(depth: (depth * factor).clamp(0.0, 0.5));

  /// Interpolates two lists of waves.
  ///
  /// When the lists pair up (same length, and the same [lobes] and [speed]
  /// at each index) the depths and phases are interpolated. Otherwise [a]
  /// fades out while [b] fades in, so the shape still changes smoothly and
  /// every wave keeps an integer [speed].
  static List<LiquidWave> lerpList(
    List<LiquidWave> a,
    List<LiquidWave> b,
    double t,
  ) {
    if (t <= 0) return a;
    if (t >= 1) return b;
    final paired =
        a.length == b.length &&
        Iterable<int>.generate(
          a.length,
        ).every((i) => a[i].lobes == b[i].lobes && a[i].speed == b[i].speed);
    if (paired) {
      return [
        for (var i = 0; i < a.length; i++)
          a[i].copyWith(
            depth: lerpDouble(a[i].depth, b[i].depth, t),
            phase: lerpDouble(a[i].phase, b[i].phase, t),
          ),
      ];
    }
    return [for (final w in a) w.scaled(1 - t), for (final w in b) w.scaled(t)];
  }

  @override
  bool operator ==(Object other) =>
      other is LiquidWave &&
      other.lobes == lobes &&
      other.depth == depth &&
      other.speed == speed &&
      other.phase == phase;

  @override
  int get hashCode => Object.hash(lobes, depth, speed, phase);

  @override
  String toString() =>
      'LiquidWave(lobes: $lobes, depth: $depth, speed: $speed, phase: $phase)';
}
