## 0.1.1

* Add a live demo at https://rudraveersandhu.github.io/liquid-fab/, linked from the README and as the
  package homepage.
* The example playground shows the Dart for the current settings, with a copy
  button.

## 0.1.0

* First release.
* `LiquidFab`: a floating action button drawn as a glossy liquid ball with a
  rippling edge and a fixed size. Hover answers with light, a press darkens
  the surface; haptics, keyboard activation, semantics, a tooltip, a fade
  in and out with `visible`, and an animated swap between `child` and
  `openChild`. Hover/press scale, a breath and a drop shadow are opt-in.
* `LiquidFabStyle`: immutable style with `copyWith`, `lerp` and
  `LiquidFabStyleTween`; presets `crimson`, `ink`, `ocean` (default),
  `graphite`, `pearl`, and `fromColor` to derive a style from one colour.
* `LiquidWave`: wave specs with integer speeds, so the loop is seamless.
* `LiquidFabPainter`: the drawing on its own, for use with `CustomPaint`.
* Holds still when the platform asks for reduced motion (opt out with
  `respectReduceMotion: false`) or when `playing` is false.
