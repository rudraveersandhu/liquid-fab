// Renders the README's media from the real widgets:
//
//   * build/readme_media/frames/frame_###.png, one loop of the presets
//     (assembled into doc/presets.gif by tool/make_readme_media.sh), and
//   * ../doc/playground.png, the example app.
//
// Run it through tool/make_readme_media.sh, which points FONTS_DIR at the
// Roboto and Material Icons fonts that ship with the Flutter SDK so text and
// icons render for real instead of as test boxes.

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_fab/liquid_fab.dart';
import 'package:liquid_fab_example/main.dart';

const _frameCount = 150; // 20 fps over the default 7.5 s loop.
const _frameStep = Duration(milliseconds: 50);
const _pixelRatio = 2.0;

Future<void> _loadFont(String family, List<String> files) async {
  final dir = Platform.environment['FONTS_DIR'];
  if (dir == null) throw StateError('Set FONTS_DIR; see make_readme_media.sh');
  final loader = FontLoader(family);
  for (final f in files) {
    final bytes = File('$dir/$f').readAsBytesSync();
    loader.addFont(Future.value(ByteData.sublistView(bytes)));
  }
  await loader.load();
}

Future<void> _capture(WidgetTester tester, GlobalKey key, String path) async {
  await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: _pixelRatio);
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    File(path)
      ..createSync(recursive: true)
      ..writeAsBytesSync(png!.buffer.asUint8List());
  });
}

void _setView(WidgetTester tester, Size logical) {
  tester.view.physicalSize = logical * _pixelRatio;
  tester.view.devicePixelRatio = _pixelRatio;
  addTearDown(tester.view.reset);
}

void main() {
  setUpAll(() async {
    await _loadFont('Roboto', [
      'Roboto-Regular.ttf',
      'Roboto-Medium.ttf',
      'Roboto-Bold.ttf',
    ]);
    await _loadFont('MaterialIcons', ['MaterialIcons-Regular.otf']);
    // The SDK ships no monospace font; the web build falls back to a sans
    // face for the code panel too, so this matches what visitors see.
    await _loadFont('monospace', ['Roboto-Regular.ttf']);
  });

  testWidgets('presets loop', (tester) async {
    const size = Size(780, 170);
    _setView(tester, size);
    final key = GlobalKey();
    final open = ValueNotifier(false);
    final presets = <String, LiquidFabStyle>{
      'crimson': const LiquidFabStyle.crimson(),
      'ink': const LiquidFabStyle.ink(),
      'ocean': const LiquidFabStyle.ocean(),
      'graphite': const LiquidFabStyle.graphite(),
      'pearl': const LiquidFabStyle.pearl(),
      'fromColor(teal)': LiquidFabStyle.fromColor(const Color(0xFF0F766E)),
    };

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: RepaintBoundary(
          key: key,
          child: Material(
            color: const Color(0xFFF6F3EE),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (final e in presets.entries)
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ValueListenableBuilder(
                          valueListenable: open,
                          builder:
                              (context, isOpen, _) => LiquidFab(
                                style: e.value,
                                diameter: 72,
                                padding: 14,
                                // The first ball shows the open/close swap.
                                open: e.key == 'crimson' && isOpen,
                                enableHaptics: false,
                                onTap: () {},
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          e.key,
                          style: const TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF5A554E),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    // The third ball (ocean) shows the hover light.
    final hoverTarget = tester.getCenter(find.byType(LiquidFab).at(2));
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    addTearDown(mouse.removePointer);

    for (var i = 0; i < _frameCount; i++) {
      if (i == 30) open.value = true;
      if (i == 100) open.value = false;
      if (i == 55) await mouse.moveTo(hoverTarget);
      if (i == 85) await mouse.moveTo(Offset.zero);
      await tester.pump();
      await _capture(
        tester,
        key,
        'build/readme_media/frames/frame_${i.toString().padLeft(3, '0')}.png',
      );
      await tester.pump(_frameStep);
    }
  });

  testWidgets('playground screenshot', (tester) async {
    // Tall enough that the floating ball sits below the last controls.
    _setView(tester, const Size(1200, 1150));
    final key = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(key: key, child: const ExampleApp()),
    );
    // Let the first style and hover tweens settle; the ripple keeps running.
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 1900));
    await _capture(tester, key, '../doc/playground.png');
  });
}
