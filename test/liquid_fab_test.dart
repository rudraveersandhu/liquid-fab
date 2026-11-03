import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_fab/liquid_fab.dart';

Widget _host(Widget child, {bool reduceMotion = false}) => MaterialApp(
  home: Builder(
    builder:
        (context) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(disableAnimations: reduceMotion),
          child: Scaffold(body: Center(child: child)),
        ),
  ),
);

final _ballPaint = find.byWidgetPredicate(
  (w) => w is CustomPaint && w.painter is LiquidFabPainter,
);

LiquidFabPainter _painter(WidgetTester tester) =>
    tester.widget<CustomPaint>(_ballPaint).painter! as LiquidFabPainter;

// The button's own node, below the fade and exclusion wrappers.
final _buttonSemantics =
    find
        .descendant(
          of: find.byType(LiquidFab),
          matching: find.byType(Semantics),
        )
        .first;

double _scale(WidgetTester tester) =>
    tester
        .widget<AnimatedScale>(
          find.descendant(
            of: find.byType(LiquidFab),
            matching: find.byType(AnimatedScale),
          ),
        )
        .scale;

void main() {
  testWidgets('renders the ball and the default chat icon', (tester) async {
    await tester.pumpWidget(_host(LiquidFab(onTap: () {})));

    expect(_ballPaint, findsOneWidget);
    expect(find.byIcon(Icons.chat_bubble_rounded), findsOneWidget);
    expect(tester.getSize(find.byType(LiquidFab)), const Size(86, 86));
  });

  testWidgets('size follows diameter and padding', (tester) async {
    await tester.pumpWidget(
      _host(LiquidFab(onTap: () {}, diameter: 40, padding: 4)),
    );
    expect(tester.getSize(find.byType(LiquidFab)), const Size(48, 48));
    expect(_painter(tester).padding, 4);
  });

  testWidgets('the ripple advances while playing', (tester) async {
    await tester.pumpWidget(_host(LiquidFab(onTap: () {})));
    final before = _painter(tester).progress;
    await tester.pump(const Duration(seconds: 1));
    expect(_painter(tester).progress, isNot(before));
    expect(tester.binding.hasScheduledFrame, isTrue);
  });

  testWidgets('tap calls onTap with a haptic tick', (tester) async {
    final haptics = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'HapticFeedback.vibrate') haptics.add(call);
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    var taps = 0;
    await tester.pumpWidget(_host(LiquidFab(onTap: () => taps++)));

    await tester.tap(find.byType(LiquidFab));
    expect(taps, 1);
    expect(haptics, hasLength(1));
    expect(haptics.single.arguments, 'HapticFeedbackType.lightImpact');

    await tester.pumpWidget(
      _host(LiquidFab(onTap: () => taps++, enableHaptics: false)),
    );
    await tester.tap(find.byType(LiquidFab));
    expect(taps, 2);
    expect(haptics, hasLength(1));
  });

  testWidgets('by default a press darkens without scaling', (tester) async {
    await tester.pumpWidget(_host(LiquidFab(onTap: () {})));
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(LiquidFab)),
    );
    await tester.pump();
    expect(_scale(tester), 1.0);
    expect(_painter(tester).pressed, isTrue);
    await gesture.up();
    await tester.pump();
    expect(_painter(tester).pressed, isFalse);
  });

  testWidgets('by default hover lights up without scaling', (tester) async {
    await tester.pumpWidget(_host(LiquidFab(onTap: () {})));
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    addTearDown(mouse.removePointer);
    await mouse.moveTo(tester.getCenter(find.byType(LiquidFab)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    final midway = _painter(tester).hover;
    expect(midway, inExclusiveRange(0, 1));
    await tester.pump(const Duration(milliseconds: 100));
    expect(_painter(tester).hover, 1);
    expect(_scale(tester), 1.0);
  });

  testWidgets('visible: false fades out, ignores taps and stops', (
    tester,
  ) async {
    var taps = 0;
    Widget fab(bool visible) =>
        _host(LiquidFab(onTap: () => taps++, visible: visible));
    await tester.pumpWidget(fab(false));
    await tester.pumpAndSettle();
    expect(tester.binding.hasScheduledFrame, isFalse);
    final opacity = tester.widget<AnimatedOpacity>(
      find.descendant(
        of: find.byType(LiquidFab),
        matching: find.byType(AnimatedOpacity),
      ),
    );
    expect(opacity.opacity, 0);
    await tester.tap(find.byType(LiquidFab), warnIfMissed: false);
    expect(taps, 0);

    await tester.pumpWidget(fab(true));
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.binding.hasScheduledFrame, isTrue);
    await tester.tap(find.byType(LiquidFab));
    expect(taps, 1);
  });

  testWidgets('opt-in press scale scales down, release restores', (
    tester,
  ) async {
    await tester.pumpWidget(_host(LiquidFab(onTap: () {}, pressScale: 0.9)));
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(LiquidFab)),
    );
    await tester.pump();
    expect(_scale(tester), 0.9);
    await gesture.up();
    await tester.pump();
    expect(_scale(tester), 1.0);
  });

  testWidgets('open swaps the child for openChild', (tester) async {
    Widget fab(bool open) => _host(
      LiquidFab(
        onTap: () {},
        open: open,
        openChild: const Text('close'),
        child: const Text('ask'),
      ),
    );
    await tester.pumpWidget(fab(false));
    expect(find.text('ask'), findsOneWidget);
    expect(find.text('close'), findsNothing);

    await tester.pumpWidget(fab(true));
    await tester.pump(const Duration(milliseconds: 100));
    // Mid-swap both are present.
    expect(find.text('ask'), findsOneWidget);
    expect(find.text('close'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('ask'), findsNothing);
    expect(find.text('close'), findsOneWidget);
  });

  testWidgets('default open child is a close icon', (tester) async {
    await tester.pumpWidget(_host(LiquidFab(onTap: () {}, open: true)));
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);
  });

  testWidgets('reduce motion stops the ticker', (tester) async {
    await tester.pumpWidget(_host(LiquidFab(onTap: () {}), reduceMotion: true));
    // Settles because nothing repeats.
    await tester.pumpAndSettle();
    expect(tester.binding.hasScheduledFrame, isFalse);
    final held = _painter(tester).progress;
    await tester.pump(const Duration(seconds: 2));
    expect(_painter(tester).progress, held);
  });

  testWidgets('respectReduceMotion: false keeps it moving', (tester) async {
    await tester.pumpWidget(
      _host(
        LiquidFab(onTap: () {}, respectReduceMotion: false),
        reduceMotion: true,
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.binding.hasScheduledFrame, isTrue);
  });

  testWidgets('playing: false pauses and true resumes', (tester) async {
    await tester.pumpWidget(_host(LiquidFab(onTap: () {}, playing: false)));
    await tester.pumpAndSettle();
    expect(tester.binding.hasScheduledFrame, isFalse);

    await tester.pumpWidget(_host(LiquidFab(onTap: () {})));
    await tester.pump(const Duration(milliseconds: 500));
    expect(_painter(tester).progress, greaterThan(0));
    expect(tester.binding.hasScheduledFrame, isTrue);
  });

  testWidgets('hover scales up and raises the glow', (tester) async {
    await tester.pumpWidget(_host(LiquidFab(onTap: () {}, hoverScale: 1.1)));
    expect(_scale(tester), 1.0);
    expect(_painter(tester).hover, 0);

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    addTearDown(mouse.removePointer);
    await mouse.moveTo(tester.getCenter(find.byType(LiquidFab)));
    await tester.pump();
    expect(_scale(tester), 1.1);
    await tester.pump(const Duration(milliseconds: 200));
    expect(_painter(tester).hover, 1);

    await mouse.moveTo(Offset.zero);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(_scale(tester), 1.0);
    expect(_painter(tester).hover, 0);
  });

  testWidgets('shows a click cursor when enabled', (tester) async {
    await tester.pumpWidget(_host(LiquidFab(onTap: () {})));
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: tester.getCenter(find.byType(LiquidFab)));
    addTearDown(mouse.removePointer);
    await tester.pump();
    expect(
      RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1),
      SystemMouseCursors.click,
    );
  });

  testWidgets('disabled when onTap is null', (tester) async {
    await tester.pumpWidget(_host(const LiquidFab()));
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(LiquidFab)),
    );
    await tester.pump();
    expect(_scale(tester), 1.0);
    await gesture.up();

    final handle = tester.ensureSemantics();
    expect(
      tester.getSemantics(_buttonSemantics),
      isSemantics(isButton: true, isEnabled: false, hasTapAction: false),
    );
    handle.dispose();
  });

  testWidgets('semantics label follows open', (tester) async {
    final handle = tester.ensureSemantics();
    Widget fab(bool open) => _host(
      LiquidFab(
        onTap: () {},
        open: open,
        semanticLabel: 'Open chat',
        openSemanticLabel: 'Close chat',
      ),
    );
    await tester.pumpWidget(fab(false));
    expect(find.bySemanticsLabel('Open chat'), findsOneWidget);
    await tester.pumpWidget(fab(true));
    expect(find.bySemanticsLabel('Close chat'), findsOneWidget);
    expect(
      tester.getSemantics(_buttonSemantics),
      isSemantics(
        label: 'Close chat',
        isButton: true,
        isEnabled: true,
        isFocusable: true,
        hasTapAction: true,
      ),
    );
    handle.dispose();
  });

  testWidgets('activates from the keyboard', (tester) async {
    var taps = 0;
    final focus = FocusNode();
    addTearDown(focus.dispose);
    await tester.pumpWidget(
      _host(LiquidFab(onTap: () => taps++, focusNode: focus)),
    );
    focus.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(taps, 1);
  });

  testWidgets('a style change animates', (tester) async {
    const from = LiquidFabStyle.crimson();
    const to = LiquidFabStyle.pearl();
    await tester.pumpWidget(_host(LiquidFab(onTap: () {}, style: from)));
    expect(_painter(tester).style, from);

    await tester.pumpWidget(_host(LiquidFab(onTap: () {}, style: to)));
    await tester.pump(const Duration(milliseconds: 150));
    final mid = _painter(tester).style;
    expect(mid, isNot(from));
    expect(mid, isNot(to));

    await tester.pump(const Duration(milliseconds: 200));
    expect(_painter(tester).style, to);
  });

  testWidgets('changing loopDuration keeps it running', (tester) async {
    await tester.pumpWidget(_host(LiquidFab(onTap: () {})));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpWidget(
      _host(LiquidFab(onTap: () {}, loopDuration: const Duration(seconds: 2))),
    );
    final a = _painter(tester).progress;
    await tester.pump(const Duration(milliseconds: 500));
    final b = _painter(tester).progress;
    // A quarter of the new 2 s loop, allowing for wrap-around.
    expect(((b - a) % 1 - 0.25).abs(), lessThan(0.01));
  });

  testWidgets('tooltip wraps the ball when given', (tester) async {
    await tester.pumpWidget(_host(LiquidFab(onTap: () {}, tooltip: 'Ask')));
    expect(find.byType(Tooltip), findsOneWidget);
  });
}
