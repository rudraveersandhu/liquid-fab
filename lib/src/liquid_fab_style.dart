import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import 'liquid_wave.dart';

/// The look of a [LiquidFab]: shape, motion, colours, halo, hover and press
/// light, gloss, rim and an optional shadow.
///
/// Immutable, with [copyWith] and [lerp], so it can be animated (the
/// [LiquidFab] widget animates between styles on its own; see also
/// [LiquidFabStyleTween]).
///
/// Every field has a default; the default style is the [LiquidFabStyle.ocean]
/// blue. Use a preset ([LiquidFabStyle.crimson], [LiquidFabStyle.ink],
/// [LiquidFabStyle.ocean], [LiquidFabStyle.graphite], [LiquidFabStyle.pearl])
/// or derive one from a single colour with [LiquidFabStyle.fromColor].
@immutable
class LiquidFabStyle with Diagnosticable {
  /// Creates a style. Every field is optional.
  const LiquidFabStyle({
    this.colors = _oceanSurface,
    this.stops,
    this.gradientCenter = const Alignment(-0.35, -0.45),
    this.gradientRadius = 1.3,
    this.coreRatio = 0.97,
    this.waves = defaultWaves,
    this.pointCount = 240,
    this.breathAmount = 0,
    this.breathCycles = 2,
    this.haloColor,
    this.haloOpacity = 0.38,
    this.haloBlur = 22,
    this.haloHoverBoost = 1.35,
    this.hoverOverlayColor = const Color(0xFFFFFFFF),
    this.hoverOverlayOpacity = 0.07,
    this.pressOverlayColor = const Color(0xFF000000),
    this.pressOverlayOpacity = 0.12,
    this.showShadow = false,
    this.shadowColor,
    this.elevation = 16,
    this.hoverElevation = 16,
    this.showGloss = true,
    this.glossColor = const Color(0xFFFFFFFF),
    this.glossOpacity = 0.34,
    this.glossSize = const Size(0.95, 0.5),
    this.glossOffset = const Offset(-0.3, -0.45),
    this.rimWidth = 1.2,
    this.rimColor,
    this.rimOpacity = 0.6,
    this.iconColor = const Color(0xFFFFFFFF),
  }) : assert(gradientRadius > 0, 'gradientRadius must be positive'),
       assert(coreRatio > 0 && coreRatio <= 1, 'coreRatio must be in (0, 1]'),
       assert(pointCount >= 8, 'pointCount must be at least 8'),
       assert(
         breathAmount >= 0 && breathAmount < 0.5,
         'breathAmount must be in [0, 0.5)',
       ),
       assert(breathCycles >= 0, 'breathCycles must be zero or more'),
       assert(
         haloOpacity >= 0 && haloOpacity <= 1,
         'haloOpacity must be in [0, 1]',
       ),
       assert(haloBlur >= 0, 'haloBlur must be zero or more'),
       assert(haloHoverBoost >= 0, 'haloHoverBoost must be zero or more'),
       assert(
         hoverOverlayOpacity >= 0 && hoverOverlayOpacity <= 1,
         'hoverOverlayOpacity must be in [0, 1]',
       ),
       assert(
         pressOverlayOpacity >= 0 && pressOverlayOpacity <= 1,
         'pressOverlayOpacity must be in [0, 1]',
       ),
       assert(elevation >= 0, 'elevation must be zero or more'),
       assert(hoverElevation >= 0, 'hoverElevation must be zero or more'),
       assert(
         glossOpacity >= 0 && glossOpacity <= 1,
         'glossOpacity must be in [0, 1]',
       ),
       assert(rimWidth >= 0, 'rimWidth must be zero or more'),
       assert(
         rimOpacity >= 0 && rimOpacity <= 1,
         'rimOpacity must be in [0, 1]',
       );

  /// Builds a full style from one [color]: a four-stop ramp from a lit tint
  /// to a shaded edge, with a halo and rim to match.
  ///
  /// Any other field can be passed through to override the derived look.
  factory LiquidFabStyle.fromColor(
    Color color, {
    Color iconColor = const Color(0xFFFFFFFF),
    Color? haloColor,
    Color? shadowColor,
    Color? rimColor,
  }) {
    return LiquidFabStyle(
      colors: [
        _shiftLightness(color, 0.21),
        _shiftLightness(color, 0.12),
        color,
        _shiftLightness(color, -0.13),
      ],
      haloColor: haloColor ?? _shiftLightness(color, 0.12),
      shadowColor: shadowColor,
      rimColor: rimColor ?? _shiftLightness(color, 0.36),
      iconColor: iconColor,
    );
  }

  /// Deep crimson (`#9B1C1C`), lit to `#BF3636` at the highlight: the
  /// original FracGC launcher.
  const LiquidFabStyle.crimson()
    : this(
        colors: const [
          Color(0xFFD9504A),
          Color(0xFFBF3636),
          Color(0xFF9B1C1C),
          Color(0xFF661010),
        ],
        haloColor: const Color(0xFFBF3636),
        haloOpacity: 0.38,
        rimColor: const Color(0xFFEE8A82),
        rimOpacity: 0.6,
      );

  /// Near-black warm ink (`#1A1814`) with a crimson glow and rim.
  const LiquidFabStyle.ink()
    : this(
        colors: const [
          Color(0xFF55504A),
          Color(0xFF2E2A25),
          Color(0xFF1A1814),
          Color(0xFF0A0908),
        ],
        haloColor: const Color(0xFF9B1C1C),
        haloOpacity: 0.32,
        rimColor: const Color(0xFFBF3636),
        rimOpacity: 0.7,
      );

  /// A clear mid blue. This is also the default style.
  const LiquidFabStyle.ocean() : this();

  /// A neutral cool grey with a soft grey glow.
  const LiquidFabStyle.graphite()
    : this(
        colors: const [
          Color(0xFF8A9099),
          Color(0xFF5F656E),
          Color(0xFF3E434A),
          Color(0xFF1F2226),
        ],
        haloColor: const Color(0xFF5F656E),
        haloOpacity: 0.3,
        rimColor: const Color(0xFFB8BEC6),
        rimOpacity: 0.5,
      );

  /// A light pearl ball with a dark icon, for dark backgrounds or light,
  /// airy layouts.
  const LiquidFabStyle.pearl()
    : this(
        colors: const [
          Color(0xFFFFFFFF),
          Color(0xFFF3F1EE),
          Color(0xFFDAD6D0),
          Color(0xFFADA79F),
        ],
        haloColor: const Color(0xFF8A8278),
        haloOpacity: 0.25,
        glossOpacity: 0.6,
        rimColor: const Color(0xFFFFFFFF),
        rimOpacity: 0.8,
        iconColor: const Color(0xFF2A2724),
      );

  static const _oceanSurface = [
    Color(0xFF6FA8FF),
    Color(0xFF3D7BEA),
    Color(0xFF2556C4),
    Color(0xFF12307A),
  ];

  /// The default edge motion: three shallow travelling waves (3, 4 and 2
  /// lobes, moving +2, −2 and +1 cycles per loop). Round, but alive.
  static const defaultWaves = [
    LiquidWave(lobes: 3, depth: 0.013, speed: 2),
    LiquidWave(lobes: 4, depth: 0.008, speed: -2),
    LiquidWave(lobes: 2, depth: 0.0045, speed: 1),
  ];

  /// Surface gradient colours, from the lit highlight to the shaded edge.
  /// At least two.
  final List<Color> colors;

  /// Positions of [colors] along the gradient, from 0 to 1, ascending. Null
  /// spaces them evenly.
  final List<double>? stops;

  /// Centre of the surface's radial gradient, where the light hits.
  final Alignment gradientCenter;

  /// Radius of the surface's radial gradient, as a fraction of the gradient
  /// box (one and a half times the ball's radius).
  final double gradientRadius;

  /// The resting radius of the edge as a fraction of the available radius.
  /// The waves move the edge around this.
  final double coreRatio;

  /// The travelling waves that ripple the edge. Empty for a perfect circle.
  final List<LiquidWave> waves;

  /// How many points trace the edge. More is smoother and slower.
  final int pointCount;

  /// How far the whole ball swells and shrinks, as a fraction of its size
  /// (`0.025` is ±2.5%). `0` turns the breath off.
  final double breathAmount;

  /// Breaths per animation loop. An integer, so the loop stays seamless.
  final int breathCycles;

  /// Colour of the diffused glow behind the ball. Null uses `colors[1]`.
  final Color? haloColor;

  /// Opacity of the glow. `0` turns it off.
  final double haloOpacity;

  /// Blur sigma of the glow, in logical pixels.
  final double haloBlur;

  /// Multiplier on [haloOpacity] while hovered.
  final double haloHoverBoost;

  /// Colour washed over the surface while hovered.
  final Color hoverOverlayColor;

  /// Opacity of [hoverOverlayColor] when fully hovered. `0` turns it off.
  final double hoverOverlayOpacity;

  /// Colour washed over the surface while pressed.
  final Color pressOverlayColor;

  /// Opacity of [pressOverlayColor] while pressed. `0` turns it off.
  final double pressOverlayOpacity;

  /// Whether to draw a floating drop shadow. Off by default: the halo already
  /// lifts the ball.
  final bool showShadow;

  /// Colour of the floating shadow. Null uses the second-darkest of
  /// [colors].
  final Color? shadowColor;

  /// Shadow elevation at rest.
  final double elevation;

  /// Shadow elevation while hovered. The same as [elevation] by default, so
  /// hover answers with light only.
  final double hoverElevation;

  /// Whether to draw the glossy highlight.
  final bool showGloss;

  /// Colour of the glossy highlight.
  final Color glossColor;

  /// Peak opacity of the glossy highlight.
  final double glossOpacity;

  /// Width and height of the highlight's oval, as fractions of the radius.
  final Size glossSize;

  /// Offset of the highlight's centre from the ball's centre, as fractions of
  /// the radius.
  final Offset glossOffset;

  /// Width of the illuminated rim, in logical pixels. `0` turns it off.
  final double rimWidth;

  /// Colour of the rim. Null uses a lightened `colors.first`.
  final Color? rimColor;

  /// Opacity of the rim.
  final double rimOpacity;

  /// Default colour for the icon or child drawn on the ball (applied through
  /// [IconTheme] and [DefaultTextStyle]).
  final Color iconColor;

  /// [haloColor], or the colour it falls back to.
  Color get effectiveHaloColor => haloColor ?? colors[1];

  /// [shadowColor], or the colour it falls back to.
  Color get effectiveShadowColor =>
      shadowColor ?? colors[math.max(0, colors.length - 2)];

  /// [rimColor], or the colour it falls back to.
  Color get effectiveRimColor =>
      rimColor ?? _shiftLightness(colors.first, 0.15);

  /// The breath scale at loop [progress] (0 to 1), centred on 1.
  double breathScaleAt(double progress) =>
      1 + breathAmount * math.sin(breathCycles * progress * 2 * math.pi);

  /// The furthest the edge can reach, as a fraction of the available radius.
  double get maxExtent =>
      coreRatio + waves.fold<double>(0, (sum, w) => sum + w.depth);

  /// Checks the parts of the style a const constructor can't: list lengths
  /// and orders. Call it inside `assert`. Throws a [FlutterError] on a
  /// problem; returns true otherwise.
  bool debugAssertIsValid() {
    if (colors.length < 2) {
      throw FlutterError('LiquidFabStyle.colors needs at least two colours.');
    }
    final s = stops;
    if (s != null) {
      if (s.length != colors.length) {
        throw FlutterError(
          'LiquidFabStyle.stops has ${s.length} entries but colors has '
          '${colors.length}.',
        );
      }
      for (var i = 0; i < s.length; i++) {
        if (s[i] < 0 || s[i] > 1 || (i > 0 && s[i] < s[i - 1])) {
          throw FlutterError(
            'LiquidFabStyle.stops must ascend from 0 to 1; got $s.',
          );
        }
      }
    }
    return true;
  }

  /// Returns a copy with the given fields replaced.
  LiquidFabStyle copyWith({
    List<Color>? colors,
    List<double>? stops,
    Alignment? gradientCenter,
    double? gradientRadius,
    double? coreRatio,
    List<LiquidWave>? waves,
    int? pointCount,
    double? breathAmount,
    int? breathCycles,
    Color? haloColor,
    double? haloOpacity,
    double? haloBlur,
    double? haloHoverBoost,
    Color? hoverOverlayColor,
    double? hoverOverlayOpacity,
    Color? pressOverlayColor,
    double? pressOverlayOpacity,
    bool? showShadow,
    Color? shadowColor,
    double? elevation,
    double? hoverElevation,
    bool? showGloss,
    Color? glossColor,
    double? glossOpacity,
    Size? glossSize,
    Offset? glossOffset,
    double? rimWidth,
    Color? rimColor,
    double? rimOpacity,
    Color? iconColor,
  }) {
    return LiquidFabStyle(
      colors: colors ?? this.colors,
      // New colours with a different count make the old stops invalid.
      stops:
          stops ??
          (colors != null && colors.length != this.colors.length
              ? null
              : this.stops),
      gradientCenter: gradientCenter ?? this.gradientCenter,
      gradientRadius: gradientRadius ?? this.gradientRadius,
      coreRatio: coreRatio ?? this.coreRatio,
      waves: waves ?? this.waves,
      pointCount: pointCount ?? this.pointCount,
      breathAmount: breathAmount ?? this.breathAmount,
      breathCycles: breathCycles ?? this.breathCycles,
      haloColor: haloColor ?? this.haloColor,
      haloOpacity: haloOpacity ?? this.haloOpacity,
      haloBlur: haloBlur ?? this.haloBlur,
      haloHoverBoost: haloHoverBoost ?? this.haloHoverBoost,
      hoverOverlayColor: hoverOverlayColor ?? this.hoverOverlayColor,
      hoverOverlayOpacity: hoverOverlayOpacity ?? this.hoverOverlayOpacity,
      pressOverlayColor: pressOverlayColor ?? this.pressOverlayColor,
      pressOverlayOpacity: pressOverlayOpacity ?? this.pressOverlayOpacity,
      showShadow: showShadow ?? this.showShadow,
      shadowColor: shadowColor ?? this.shadowColor,
      elevation: elevation ?? this.elevation,
      hoverElevation: hoverElevation ?? this.hoverElevation,
      showGloss: showGloss ?? this.showGloss,
      glossColor: glossColor ?? this.glossColor,
      glossOpacity: glossOpacity ?? this.glossOpacity,
      glossSize: glossSize ?? this.glossSize,
      glossOffset: glossOffset ?? this.glossOffset,
      rimWidth: rimWidth ?? this.rimWidth,
      rimColor: rimColor ?? this.rimColor,
      rimOpacity: rimOpacity ?? this.rimOpacity,
      iconColor: iconColor ?? this.iconColor,
    );
  }

  /// Interpolates between two styles.
  ///
  /// Colours, numbers and geometry are blended; gradients with different
  /// colour counts are resampled; [waves] are blended with
  /// [LiquidWave.lerpList] so the loop stays seamless. Integer and boolean
  /// fields switch halfway, except [showShadow] and [showGloss], which fade.
  static LiquidFabStyle? lerp(LiquidFabStyle? a, LiquidFabStyle? b, double t) {
    if (identical(a, b)) return a;
    if (a == null) return b;
    if (b == null) return a;
    if (t <= 0) return a;
    if (t >= 1) return b;

    final (colors, stops) = _lerpGradient(a, b, t);
    // A shadow or gloss turning on or off fades in or out.
    final shadowA =
        a.showShadow
            ? a.effectiveShadowColor
            : a.effectiveShadowColor.withValues(alpha: 0);
    final shadowB =
        b.showShadow
            ? b.effectiveShadowColor
            : b.effectiveShadowColor.withValues(alpha: 0);
    final glossA = a.showGloss ? a.glossOpacity : 0.0;
    final glossB = b.showGloss ? b.glossOpacity : 0.0;

    return LiquidFabStyle(
      colors: colors,
      stops: stops,
      gradientCenter: Alignment.lerp(a.gradientCenter, b.gradientCenter, t)!,
      gradientRadius: lerpDouble(a.gradientRadius, b.gradientRadius, t)!,
      coreRatio: lerpDouble(a.coreRatio, b.coreRatio, t)!,
      waves: LiquidWave.lerpList(a.waves, b.waves, t),
      pointCount: lerpDouble(a.pointCount, b.pointCount, t)!.round(),
      breathAmount: lerpDouble(a.breathAmount, b.breathAmount, t)!,
      breathCycles: t < 0.5 ? a.breathCycles : b.breathCycles,
      haloColor: Color.lerp(a.effectiveHaloColor, b.effectiveHaloColor, t),
      haloOpacity: lerpDouble(a.haloOpacity, b.haloOpacity, t)!,
      haloBlur: lerpDouble(a.haloBlur, b.haloBlur, t)!,
      haloHoverBoost: lerpDouble(a.haloHoverBoost, b.haloHoverBoost, t)!,
      hoverOverlayColor:
          Color.lerp(a.hoverOverlayColor, b.hoverOverlayColor, t)!,
      hoverOverlayOpacity:
          lerpDouble(a.hoverOverlayOpacity, b.hoverOverlayOpacity, t)!,
      pressOverlayColor:
          Color.lerp(a.pressOverlayColor, b.pressOverlayColor, t)!,
      pressOverlayOpacity:
          lerpDouble(a.pressOverlayOpacity, b.pressOverlayOpacity, t)!,
      showShadow: a.showShadow || b.showShadow,
      shadowColor: Color.lerp(shadowA, shadowB, t),
      elevation: lerpDouble(a.elevation, b.elevation, t)!,
      hoverElevation: lerpDouble(a.hoverElevation, b.hoverElevation, t)!,
      showGloss: a.showGloss || b.showGloss,
      glossColor: Color.lerp(a.glossColor, b.glossColor, t)!,
      glossOpacity: lerpDouble(glossA, glossB, t)!,
      glossSize: Size.lerp(a.glossSize, b.glossSize, t)!,
      glossOffset: Offset.lerp(a.glossOffset, b.glossOffset, t)!,
      rimWidth: lerpDouble(a.rimWidth, b.rimWidth, t)!,
      rimColor: Color.lerp(a.effectiveRimColor, b.effectiveRimColor, t),
      rimOpacity: lerpDouble(a.rimOpacity, b.rimOpacity, t)!,
      iconColor: Color.lerp(a.iconColor, b.iconColor, t)!,
    );
  }

  static (List<Color>, List<double>?) _lerpGradient(
    LiquidFabStyle a,
    LiquidFabStyle b,
    double t,
  ) {
    if (a.colors.length == b.colors.length) {
      final colors = [
        for (var i = 0; i < a.colors.length; i++)
          Color.lerp(a.colors[i], b.colors[i], t)!,
      ];
      if (a.stops == null && b.stops == null) return (colors, null);
      final sa = a.stops ?? _evenStops(a.colors.length);
      final sb = b.stops ?? _evenStops(b.colors.length);
      return (
        colors,
        [for (var i = 0; i < sa.length; i++) lerpDouble(sa[i], sb[i], t)!],
      );
    }
    // Different counts: sample both gradients at evenly spaced points.
    final n = math.max(a.colors.length, b.colors.length);
    final even = _evenStops(n);
    return (
      [
        for (final x in even)
          Color.lerp(
            _sample(a.colors, a.stops, x),
            _sample(b.colors, b.stops, x),
            t,
          )!,
      ],
      null,
    );
  }

  static List<double> _evenStops(int n) => [
    for (var i = 0; i < n; i++) i / (n - 1),
  ];

  static Color _sample(List<Color> colors, List<double>? stops, double x) {
    final s = stops ?? _evenStops(colors.length);
    if (x <= s.first) return colors.first;
    if (x >= s.last) return colors.last;
    for (var i = 1; i < s.length; i++) {
      if (x <= s[i]) {
        final span = s[i] - s[i - 1];
        return Color.lerp(
          colors[i - 1],
          colors[i],
          span == 0 ? 1 : (x - s[i - 1]) / span,
        )!;
      }
    }
    return colors.last;
  }

  static Color _shiftLightness(Color color, double delta) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness((hsl.lightness + delta).clamp(0.02, 0.98))
        .toColor();
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LiquidFabStyle &&
        listEquals(other.colors, colors) &&
        listEquals(other.stops, stops) &&
        other.gradientCenter == gradientCenter &&
        other.gradientRadius == gradientRadius &&
        other.coreRatio == coreRatio &&
        listEquals(other.waves, waves) &&
        other.pointCount == pointCount &&
        other.breathAmount == breathAmount &&
        other.breathCycles == breathCycles &&
        other.haloColor == haloColor &&
        other.haloOpacity == haloOpacity &&
        other.haloBlur == haloBlur &&
        other.haloHoverBoost == haloHoverBoost &&
        other.hoverOverlayColor == hoverOverlayColor &&
        other.hoverOverlayOpacity == hoverOverlayOpacity &&
        other.pressOverlayColor == pressOverlayColor &&
        other.pressOverlayOpacity == pressOverlayOpacity &&
        other.showShadow == showShadow &&
        other.shadowColor == shadowColor &&
        other.elevation == elevation &&
        other.hoverElevation == hoverElevation &&
        other.showGloss == showGloss &&
        other.glossColor == glossColor &&
        other.glossOpacity == glossOpacity &&
        other.glossSize == glossSize &&
        other.glossOffset == glossOffset &&
        other.rimWidth == rimWidth &&
        other.rimColor == rimColor &&
        other.rimOpacity == rimOpacity &&
        other.iconColor == iconColor;
  }

  @override
  int get hashCode => Object.hashAll([
    Object.hashAll(colors),
    stops == null ? null : Object.hashAll(stops!),
    gradientCenter,
    gradientRadius,
    coreRatio,
    Object.hashAll(waves),
    pointCount,
    breathAmount,
    breathCycles,
    haloColor,
    haloOpacity,
    haloBlur,
    haloHoverBoost,
    hoverOverlayColor,
    hoverOverlayOpacity,
    pressOverlayColor,
    pressOverlayOpacity,
    showShadow,
    shadowColor,
    elevation,
    hoverElevation,
    showGloss,
    glossColor,
    glossOpacity,
    glossSize,
    glossOffset,
    rimWidth,
    rimColor,
    rimOpacity,
    iconColor,
  ]);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<Color>('colors', colors))
      ..add(IterableProperty<double>('stops', stops, defaultValue: null))
      ..add(DoubleProperty('coreRatio', coreRatio))
      ..add(IterableProperty<LiquidWave>('waves', waves))
      ..add(DoubleProperty('breathAmount', breathAmount))
      ..add(IntProperty('breathCycles', breathCycles))
      ..add(ColorProperty('haloColor', haloColor, defaultValue: null))
      ..add(DoubleProperty('haloOpacity', haloOpacity))
      ..add(FlagProperty('showShadow', value: showShadow, ifFalse: 'no shadow'))
      ..add(FlagProperty('showGloss', value: showGloss, ifFalse: 'no gloss'))
      ..add(DoubleProperty('rimWidth', rimWidth))
      ..add(ColorProperty('iconColor', iconColor));
  }
}

/// A [Tween] between two [LiquidFabStyle]s, using [LiquidFabStyle.lerp].
class LiquidFabStyleTween extends Tween<LiquidFabStyle?> {
  /// Creates a style tween.
  LiquidFabStyleTween({super.begin, super.end});

  @override
  LiquidFabStyle? lerp(double t) => LiquidFabStyle.lerp(begin, end, t);
}
