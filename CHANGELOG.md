## 0.1.0

* First release.
* `LiquidFab`: a floating action button drawn as a glossy liquid ball with a
  rippling edge, a slow breath, hover and press scale, haptics, keyboard
  activation, semantics, a tooltip, and an animated swap between `child` and
  `openChild`.
* `LiquidFabStyle`: immutable style with `copyWith`, `lerp` and
  `LiquidFabStyleTween`; presets `crimson`, `ink`, `ocean` (default),
  `graphite`, `pearl`, and `fromColor` to derive a style from one colour.
* `LiquidWave`: wave specs with integer speeds, so the loop is seamless.
* `LiquidFabPainter`: the drawing on its own, for use with `CustomPaint`.
* Holds still when the platform asks for reduced motion (opt out with
  `respectReduceMotion: false`) or when `playing` is false.
