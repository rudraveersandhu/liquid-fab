import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_fab/liquid_fab.dart';

void main() {
  group('shouldRepaint', () {
    final base = LiquidFabPainter(progress: 0.2);

    test('is false for an identical frame', () {
      expect(base.shouldRepaint(LiquidFabPainter(progress: 0.2)), isFalse);
      expect(
        base.shouldRepaint(
          LiquidFabPainter(
            progress: 0.2,
            style: const LiquidFabStyle().copyWith(),
          ),
        ),
        isFalse,
      );
    });

    test('is true when progress, hover, padding or style change', () {
      expect(base.shouldRepaint(LiquidFabPainter(progress: 0.3)), isTrue);
      expect(
        base.shouldRepaint(LiquidFabPainter(progress: 0.2, hover: 0.5)),
        isTrue,
      );
      expect(
        base.shouldRepaint(LiquidFabPainter(progress: 0.2, padding: 4)),
        isTrue,
      );
      expect(
        base.shouldRepaint(
          LiquidFabPainter(
            progress: 0.2,
            style: const LiquidFabStyle(rimWidth: 2),
          ),
        ),
        isTrue,
      );
    });
  });

  test('the loop is seamless: progress 0 and 1 trace the same edge', () {
    const style = LiquidFabStyle(
      waves: [
        LiquidWave(lobes: 3, depth: 0.05, speed: 2),
        LiquidWave(lobes: 5, depth: 0.03, speed: -3, phase: 1),
      ],
    );
    final a = LiquidFabPainter.edgePath(style, Offset.zero, 50, 0);
    final b = LiquidFabPainter.edgePath(style, Offset.zero, 50, 1);
    final ab = a.getBounds(), bb = b.getBounds();
    expect(ab.left, closeTo(bb.left, 1e-9));
    expect(ab.top, closeTo(bb.top, 1e-9));
    expect(ab.right, closeTo(bb.right, 1e-9));
    expect(ab.bottom, closeTo(bb.bottom, 1e-9));

    final mid = LiquidFabPainter.edgePath(style, Offset.zero, 50, 0.3);
    expect(mid.getBounds(), isNot(ab));
  });

  test('with no waves the edge is a circle at coreRatio', () {
    const style = LiquidFabStyle(waves: [], coreRatio: 0.8);
    final bounds =
        LiquidFabPainter.edgePath(style, Offset.zero, 50, 0.4).getBounds();
    expect(bounds.width, closeTo(80, 0.01));
    expect(bounds.height, closeTo(80, 0.01));
  });

  test('asserts on an invalid style', () {
    expect(
      () => LiquidFabPainter(
        progress: 0,
        style: const LiquidFabStyle(colors: [Colors.red]),
      ),
      throwsA(isA<FlutterError>()),
    );
    expect(
      () => LiquidFabPainter(
        progress: 0,
        style: const LiquidFabStyle(
          colors: [Colors.red, Colors.blue],
          stops: [0.6, 0.2],
        ),
      ),
      throwsA(isA<FlutterError>()),
    );
  });

  test('paints a crimson ball centred on a clear canvas', () async {
    const size = 120;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    LiquidFabPainter(
      progress: 0.25,
      style: const LiquidFabStyle.crimson(),
    ).paint(canvas, const Size(120, 120));
    final image = await recorder.endRecording().toImage(size, size);
    final bytes = (await image.toByteData())!;

    // RGBA at (x, y).
    List<int> px(int x, int y) {
      final i = (y * size + x) * 4;
      return [for (var k = 0; k < 4; k++) bytes.getUint8(i + k)];
    }

    final centre = px(60, 60);
    expect(centre[3], 255, reason: 'the ball is opaque');
    expect(centre[0], greaterThan(centre[1] + 60), reason: 'and red');
    expect(centre[0], greaterThan(centre[2] + 60));

    // The corners are well outside the halo.
    expect(px(0, 0)[3], lessThan(20));
    expect(px(size - 1, size - 1)[3], lessThan(40));
    image.dispose();
  });

  test('paints nothing when padding swallows the canvas', () async {
    final recorder = ui.PictureRecorder();
    LiquidFabPainter(
      progress: 0,
      padding: 30,
    ).paint(Canvas(recorder), const Size(40, 40));
    final image = await recorder.endRecording().toImage(40, 40);
    final bytes = (await image.toByteData())!;
    expect(bytes.buffer.asUint8List().every((b) => b == 0), isTrue);
    image.dispose();
  });
}
