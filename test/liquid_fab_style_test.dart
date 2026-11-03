import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_fab/liquid_fab.dart';

void main() {
  test('presets are valid and distinct', () {
    const presets = [
      LiquidFabStyle.crimson(),
      LiquidFabStyle.ink(),
      LiquidFabStyle.ocean(),
      LiquidFabStyle.graphite(),
      LiquidFabStyle.pearl(),
    ];
    for (final p in presets) {
      expect(p.debugAssertIsValid(), isTrue);
      expect(p.maxExtent, lessThanOrEqualTo(1));
    }
    expect(presets.toSet(), hasLength(presets.length));
    expect(const LiquidFabStyle.ocean(), const LiquidFabStyle());
  });

  test('crimson matches the original launcher', () {
    const s = LiquidFabStyle.crimson();
    expect(s.colors[2], const Color(0xFF9B1C1C));
    expect(s.coreRatio, 0.97);
    expect(s.waves.map((w) => w.lobes), [3, 4, 2]);
    expect(s.waves.map((w) => w.speed), [2, -2, 1]);
    expect(s.waves.map((w) => w.depth), [0.013, 0.008, 0.0045]);
    expect(s.breathAmount, 0, reason: 'the ball never changes size');
    expect(s.haloBlur, 22);
    expect(s.haloHoverBoost, 1.35);
    expect(s.hoverOverlayOpacity, 0.07);
    expect(s.pressOverlayOpacity, 0.12);
    expect(s.showShadow, isFalse);
  });

  test('fromColor derives a light-to-dark ramp around the colour', () {
    const base = Color(0xFF2E7D32);
    final s = LiquidFabStyle.fromColor(base);
    expect(s.colors, hasLength(4));
    expect(s.colors[2], base);
    double l(Color c) => HSLColor.fromColor(c).lightness;
    expect(l(s.colors[0]), greaterThan(l(s.colors[1])));
    expect(l(s.colors[1]), greaterThan(l(s.colors[2])));
    expect(l(s.colors[2]), greaterThan(l(s.colors[3])));
  });

  test('fallback colours come from the gradient', () {
    const s = LiquidFabStyle(colors: [Colors.white, Colors.grey, Colors.black]);
    expect(s.effectiveHaloColor, Colors.grey);
    expect(s.effectiveShadowColor, Colors.grey);
    expect(s.effectiveRimColor, isNotNull);
  });

  test('copyWith replaces only what is given', () {
    const s = LiquidFabStyle.crimson();
    final c = s.copyWith(rimWidth: 3);
    expect(c.rimWidth, 3);
    expect(c.copyWith(rimWidth: s.rimWidth), s);
  });

  test('copyWith drops stops that no longer fit the colours', () {
    const s = LiquidFabStyle(
      colors: [Colors.white, Colors.black],
      stops: [0, 1],
    );
    expect(
      s.copyWith(colors: [Colors.red, Colors.blue, Colors.green]).stops,
      isNull,
    );
    expect(s.copyWith(colors: [Colors.red, Colors.blue]).stops, [0, 1]);
  });

  test('breathScaleAt is seamless and bounded', () {
    const s = LiquidFabStyle(breathAmount: 0.05, breathCycles: 3);
    expect(s.breathScaleAt(0), closeTo(s.breathScaleAt(1), 1e-12));
    for (var i = 0; i <= 100; i++) {
      final v = s.breathScaleAt(i / 100);
      expect(v, inInclusiveRange(0.95, 1.05));
    }
  });

  group('lerp', () {
    const a = LiquidFabStyle.crimson();
    const b = LiquidFabStyle.ink();

    test('ends return the ends', () {
      expect(LiquidFabStyle.lerp(a, b, 0), a);
      expect(LiquidFabStyle.lerp(a, b, 1), b);
      expect(LiquidFabStyle.lerp(null, b, 0.5), b);
      expect(LiquidFabStyle.lerp(a, null, 0.5), a);
    });

    test('blends colours and numbers', () {
      final m = LiquidFabStyle.lerp(a, b, 0.5)!;
      expect(m.colors[2], Color.lerp(a.colors[2], b.colors[2], 0.5));
      expect(m.haloOpacity, closeTo(0.35, 1e-9));
      expect(m.rimOpacity, closeTo(0.65, 1e-9));
      expect(m.debugAssertIsValid(), isTrue);
    });

    test('resamples gradients with different colour counts', () {
      const two = LiquidFabStyle(colors: [Colors.white, Colors.black]);
      final m = LiquidFabStyle.lerp(two, a, 0.5)!;
      expect(m.colors, hasLength(4));
      expect(m.stops, isNull);
      expect(m.debugAssertIsValid(), isTrue);
    });

    test('paired waves blend their depth', () {
      final deep = a.copyWith(waves: [for (final w in a.waves) w.scaled(3)]);
      final m = LiquidFabStyle.lerp(a, deep, 0.5)!;
      expect(m.waves, hasLength(3));
      expect(m.waves.first.depth, closeTo(a.waves.first.depth * 2, 1e-9));
    });

    test('unpaired waves cross-fade and keep integer speeds', () {
      final other = a.copyWith(
        waves: const [LiquidWave(lobes: 6, depth: 0.02, speed: 3)],
      );
      final m = LiquidFabStyle.lerp(a, other, 0.25)!;
      expect(m.waves, hasLength(4));
      expect(m.waves.last.depth, closeTo(0.005, 1e-9));
      expect(m.waves.first.depth, closeTo(a.waves.first.depth * 0.75, 1e-9));
      expect(m.maxExtent, lessThanOrEqualTo(1));
    });

    test('a shadow turning off fades out', () {
      final on = a.copyWith(showShadow: true);
      final m = LiquidFabStyle.lerp(on, a, 0.5)!;
      expect(m.showShadow, isTrue);
      expect(m.effectiveShadowColor.a, closeTo(0.5, 0.01));
    });

    test('the tween uses lerp', () {
      final tween = LiquidFabStyleTween(begin: a, end: b);
      expect(tween.lerp(0.5), LiquidFabStyle.lerp(a, b, 0.5));
    });
  });

  test('wave equality and copy', () {
    const w = LiquidWave(lobes: 3, depth: 0.01, speed: 2);
    expect(w, const LiquidWave(lobes: 3, depth: 0.01, speed: 2));
    expect(w.copyWith(phase: 1).phase, 1);
    expect(w.offsetAt(0, 0), 0);
  });
}
