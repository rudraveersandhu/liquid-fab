import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'liquid_fab_painter.dart';
import 'liquid_fab_style.dart';

/// A floating action button drawn as a glossy liquid ball whose edge ripples
/// gently and which breathes slowly.
///
/// ```dart
/// LiquidFab(
///   style: const LiquidFabStyle.crimson(),
///   open: chatOpen,
///   onTap: () => setState(() => chatOpen = !chatOpen),
/// )
/// ```
///
/// It shows [child] (a chat bubble by default) and swaps to [openChild] (a
/// close mark by default) with a spin and fade when [open] is true. Hovering
/// raises the halo and shadow and scales it up a little; pressing scales it
/// down. When [style] changes it animates to the new one over
/// [styleDuration].
///
/// The ripple and breath stop when [playing] is false, and, unless
/// [respectReduceMotion] is false, when the platform asks for reduced motion
/// ([MediaQueryData.disableAnimations]). The loop is seamless: every wave
/// and the breath complete a whole number of cycles per [loopDuration].
///
/// The widget's box is `diameter + 2 * padding` square; the padding leaves
/// room for the ripple, the breath and the start of the halo, which can paint
/// beyond the box.
class LiquidFab extends StatefulWidget {
  /// Creates a liquid ball button.
  const LiquidFab({
    super.key,
    this.onTap,
    this.open = false,
    this.child,
    this.openChild,
    this.style = const LiquidFabStyle(),
    this.diameter = 62,
    this.padding = 10,
    this.loopDuration = const Duration(seconds: 9),
    this.playing = true,
    this.respectReduceMotion = true,
    this.hoverScale = 1.06,
    this.pressScale = 0.93,
    this.scaleDuration = const Duration(milliseconds: 160),
    this.scaleCurve = Curves.easeOutCubic,
    this.swapDuration = const Duration(milliseconds: 220),
    this.swapTransitionBuilder = LiquidFab.spinFadeTransition,
    this.styleDuration = const Duration(milliseconds: 300),
    this.styleCurve = Curves.easeInOut,
    this.enableHaptics = true,
    this.mouseCursor,
    this.semanticLabel,
    this.openSemanticLabel,
    this.tooltip,
    this.focusNode,
    this.autofocus = false,
  }) : assert(diameter > 0, 'diameter must be positive'),
       assert(padding >= 0, 'padding must be zero or more'),
       assert(hoverScale > 0, 'hoverScale must be positive'),
       assert(pressScale > 0, 'pressScale must be positive');

  /// Called when the ball is tapped or activated from the keyboard. Null
  /// disables the button (no press feedback, no hover, a basic cursor).
  final VoidCallback? onTap;

  /// Whether to show [openChild] instead of [child].
  final bool open;

  /// What sits on the ball while closed. Defaults to a chat bubble icon.
  /// Icons and text pick up [LiquidFabStyle.iconColor].
  final Widget? child;

  /// What sits on the ball while [open]. Defaults to a close icon.
  final Widget? openChild;

  /// The look of the ball. Changes animate over [styleDuration].
  final LiquidFabStyle style;

  /// The ball's diameter at rest, in logical pixels.
  final double diameter;

  /// Extra room on each side of the ball for the ripple, breath and halo.
  final double padding;

  /// How long one full ripple loop takes. Shorter is faster.
  final Duration loopDuration;

  /// Whether the ripple and breath run. False holds the current frame.
  final bool playing;

  /// Whether to hold still when the platform asks for reduced motion.
  final bool respectReduceMotion;

  /// Scale while hovered (pointer devices).
  final double hoverScale;

  /// Scale while pressed.
  final double pressScale;

  /// Duration of the hover and press scale and of the hover glow.
  final Duration scaleDuration;

  /// Curve of the hover and press scale.
  final Curve scaleCurve;

  /// Duration of the swap between [child] and [openChild].
  final Duration swapDuration;

  /// The transition for the swap between [child] and [openChild]. Defaults
  /// to [spinFadeTransition].
  final AnimatedSwitcherTransitionBuilder swapTransitionBuilder;

  /// How long a change of [style] takes to animate. [Duration.zero] jumps.
  final Duration styleDuration;

  /// Curve of a [style] change.
  final Curve styleCurve;

  /// Whether a tap gives a light haptic tick.
  final bool enableHaptics;

  /// The cursor over the ball. Defaults to [SystemMouseCursors.click] when
  /// enabled, otherwise [MouseCursor.defer].
  final MouseCursor? mouseCursor;

  /// Screen-reader label while closed.
  final String? semanticLabel;

  /// Screen-reader label while [open]. Defaults to [semanticLabel].
  final String? openSemanticLabel;

  /// Optional tooltip text, shown on long press and hover.
  final String? tooltip;

  /// Optional focus node for keyboard focus.
  final FocusNode? focusNode;

  /// Whether to take focus when first built.
  final bool autofocus;

  /// The default swap: the incoming child spins in from 85% of a turn while
  /// fading in.
  static Widget spinFadeTransition(Widget child, Animation<double> animation) =>
      RotationTransition(
        turns: Tween<double>(begin: 0.85, end: 1).animate(animation),
        child: FadeTransition(opacity: animation, child: child),
      );

  @override
  State<LiquidFab> createState() => _LiquidFabState();
}

class _LiquidFabState extends State<LiquidFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flow = AnimationController(
    vsync: this,
    duration: widget.loopDuration,
  );
  bool _hover = false;
  bool _focused = false;
  bool _pressed = false;

  bool get _enabled => widget.onTap != null;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncFlow();
  }

  @override
  void didUpdateWidget(LiquidFab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.loopDuration != widget.loopDuration) {
      _flow.duration = widget.loopDuration;
      // A running repeat keeps its old period until restarted.
      if (_flow.isAnimating) _flow.repeat();
    }
    if (!_enabled) {
      _hover = false;
      _pressed = false;
    }
    _syncFlow();
  }

  void _syncFlow() {
    final reduce =
        widget.respectReduceMotion &&
        (MediaQuery.maybeDisableAnimationsOf(context) ?? false);
    final still = reduce || !widget.playing;
    if (still && _flow.isAnimating) {
      _flow.stop();
    } else if (!still && !_flow.isAnimating) {
      _flow.repeat();
    }
  }

  void _handleTap() {
    if (!_enabled) return;
    if (widget.enableHaptics) HapticFeedback.lightImpact();
    widget.onTap!();
  }

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  void dispose() {
    _flow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lit = _enabled && (_hover || _focused);
    final scale =
        !_enabled
            ? 1.0
            : _pressed
            ? widget.pressScale
            : lit
            ? widget.hoverScale
            : 1.0;
    final box = widget.diameter + widget.padding * 2;

    final label =
        widget.open
            ? (widget.openSemanticLabel ?? widget.semanticLabel)
            : widget.semanticLabel;

    // A label replaces whatever the child would announce.
    final face = KeyedSubtree(
      key: ValueKey<bool>(widget.open),
      child: ExcludeSemantics(
        excluding: label != null,
        child:
            widget.open
                ? (widget.openChild ?? const Icon(Icons.close_rounded))
                : (widget.child ?? const Icon(Icons.chat_bubble_rounded)),
      ),
    );

    Widget ball = TweenAnimationBuilder<LiquidFabStyle?>(
      tween: LiquidFabStyleTween(end: widget.style),
      duration: widget.styleDuration,
      curve: widget.styleCurve,
      builder: (context, animatedStyle, child) {
        final style = animatedStyle!;
        return TweenAnimationBuilder<double>(
          tween: Tween<double>(end: lit ? 1 : 0),
          duration: widget.scaleDuration,
          curve: Curves.easeOut,
          builder:
              (context, hover, child) => AnimatedBuilder(
                animation: _flow,
                builder:
                    (context, child) => Transform.scale(
                      scale: style.breathScaleAt(_flow.value),
                      child: CustomPaint(
                        painter: LiquidFabPainter(
                          progress: _flow.value,
                          style: style,
                          hover: hover.clamp(0.0, 1.0),
                          padding: widget.padding,
                        ),
                        child: child,
                      ),
                    ),
                child: child,
              ),
          child: IconTheme.merge(
            data: IconThemeData(
              color: style.iconColor,
              size: widget.diameter * 0.4,
            ),
            child: DefaultTextStyle.merge(
              style: TextStyle(color: style.iconColor),
              child: child!,
            ),
          ),
        );
      },
      child: Center(
        child: AnimatedSwitcher(
          duration: widget.swapDuration,
          transitionBuilder: widget.swapTransitionBuilder,
          child: face,
        ),
      ),
    );

    ball = AnimatedScale(
      scale: scale,
      duration: widget.scaleDuration,
      curve: widget.scaleCurve,
      child: SizedBox.square(dimension: box, child: ball),
    );

    ball = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: _enabled ? (_) => _setPressed(true) : null,
      onTapUp: _enabled ? (_) => _setPressed(false) : null,
      onTapCancel: _enabled ? () => _setPressed(false) : null,
      onTap: _enabled ? _handleTap : null,
      child: ball,
    );

    // Hover is tracked here rather than through FocusableActionDetector,
    // which only reports it while the focus highlight mode is "traditional"
    // (so not on a touch device with a mouse until its first click).
    ball = MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: ball,
    );

    ball = FocusableActionDetector(
      enabled: _enabled,
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      mouseCursor:
          widget.mouseCursor ??
          (_enabled ? SystemMouseCursors.click : MouseCursor.defer),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) => _handleTap(),
        ),
      },
      child: ball,
    );

    ball = Semantics(
      container: true,
      button: true,
      enabled: _enabled,
      label: label,
      child: ball,
    );

    if (widget.tooltip != null) {
      ball = Tooltip(message: widget.tooltip, child: ball);
    }
    return ball;
  }
}
