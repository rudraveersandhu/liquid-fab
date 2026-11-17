import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:liquid_fab/liquid_fab.dart';

void main() => runApp(const ExampleApp());

/// The example app: a row of presets and a playground with live controls.
class ExampleApp extends StatelessWidget {
  /// Creates the example app.
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'liquid_fab',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(colorSchemeSeed: const Color(0xFF9B1C1C)),
    darkTheme: ThemeData(
      colorSchemeSeed: const Color(0xFF9B1C1C),
      brightness: Brightness.dark,
    ),
    home: const _Home(),
  );
}

final _presets = <String, LiquidFabStyle>{
  'crimson': const LiquidFabStyle.crimson(),
  'ink': const LiquidFabStyle.ink(),
  'ocean': const LiquidFabStyle.ocean(),
  'graphite': const LiquidFabStyle.graphite(),
  'pearl': const LiquidFabStyle.pearl(),
  'fromColor(teal)': LiquidFabStyle.fromColor(const Color(0xFF0F766E)),
};

/// How each preset is written in Dart, for the code snippet.
const _presetCode = <String, String>{
  'crimson': 'const LiquidFabStyle.crimson()',
  'ink': 'const LiquidFabStyle.ink()',
  'ocean': 'const LiquidFabStyle.ocean()',
  'graphite': 'const LiquidFabStyle.graphite()',
  'pearl': 'const LiquidFabStyle.pearl()',
  'fromColor(teal)': 'LiquidFabStyle.fromColor(const Color(0xFF0F766E))',
};

/// A number as short as it can be at three decimals: 0.380 -> 0.38.
String _num(double v) {
  var t = v.toStringAsFixed(3);
  if (t.contains('.')) t = t.replaceFirst(RegExp(r'\.?0+$'), '');
  return t.contains('.') ? t : '$t.0';
}

class _Home extends StatefulWidget {
  const _Home();

  @override
  State<_Home> createState() => _HomeState();
}

class _HomeState extends State<_Home> {
  // Playground state.
  String _preset = 'crimson';
  double _diameter = 66;
  double _loopSeconds = 7.5;
  double _breath = 0;
  double _waveScale = 1;
  double _core = 0.97;
  double _haloOpacity = 0.38;
  double _haloBlur = 22;
  double _elevation = 16;
  bool _shadow = false;
  bool _gloss = true;
  double _glossOpacity = 0.34;
  double _rimWidth = 1.2;
  double _hoverLight = 0.07;
  double _pressDark = 0.12;
  double _hoverScale = 1;
  double _pressScale = 1;
  bool _visible = true;
  bool _playing = true;
  bool _respectReduceMotion = true;
  bool _haptics = true;
  bool _darkStage = false;
  bool _open = false;

  LiquidFabStyle get _style {
    final base = _presets[_preset]!;
    return base.copyWith(
      coreRatio: _core,
      waves: [for (final w in base.waves) w.scaled(_waveScale)],
      breathAmount: _breath,
      haloOpacity: _haloOpacity,
      haloBlur: _haloBlur,
      showShadow: _shadow,
      elevation: _elevation,
      hoverElevation: _elevation,
      hoverOverlayOpacity: _hoverLight,
      pressOverlayOpacity: _pressDark,
      showGloss: _gloss,
      glossOpacity: _glossOpacity,
      rimWidth: _rimWidth,
    );
  }

  /// The Dart that builds the stage's ball: only what differs from the
  /// preset and the widget's defaults.
  String get _code {
    final base = _presets[_preset]!;
    final style = <String>[];
    void num(String name, double value, double preset) {
      if (_num(value) != _num(preset)) style.add('$name: ${_num(value)}');
    }

    num('coreRatio', _core, base.coreRatio);
    if (_num(_waveScale) != '1.0') {
      style.add(
        'waves: [\n      for (final w in LiquidFabStyle.defaultWaves)\n'
        '        w.scaled(${_num(_waveScale)}),\n    ]',
      );
    }
    num('breathAmount', _breath, base.breathAmount);
    num('haloOpacity', _haloOpacity, base.haloOpacity);
    num('haloBlur', _haloBlur, base.haloBlur);
    num('hoverOverlayOpacity', _hoverLight, base.hoverOverlayOpacity);
    num('pressOverlayOpacity', _pressDark, base.pressOverlayOpacity);
    if (_shadow != base.showShadow) style.add('showShadow: $_shadow');
    if (_shadow) {
      num('elevation', _elevation, base.elevation);
      num('hoverElevation', _elevation, base.hoverElevation);
    }
    if (_gloss != base.showGloss) style.add('showGloss: $_gloss');
    if (_gloss) num('glossOpacity', _glossOpacity, base.glossOpacity);
    num('rimWidth', _rimWidth, base.rimWidth);

    var preset = _presetCode[_preset]!;
    if (style.isNotEmpty) {
      // copyWith isn't const, so the preset loses its const.
      preset = preset.replaceFirst('const ', '');
      preset = '$preset.copyWith(\n    ${style.join(',\n    ')},\n  )';
    }

    final args = <String>['style: $preset'];
    if (_num(_diameter) != '66.0') args.add('diameter: ${_num(_diameter)}');
    if (_num(_loopSeconds) != '7.5') {
      args.add(
        'loopDuration: const Duration(milliseconds: '
        '${(_loopSeconds * 1000).round()})',
      );
    }
    if (!_playing) args.add('playing: false');
    if (!_respectReduceMotion) args.add('respectReduceMotion: false');
    if (!_haptics) args.add('enableHaptics: false');
    if (_num(_hoverScale) != '1.0') {
      args.add('hoverScale: ${_num(_hoverScale)}');
    }
    if (_num(_pressScale) != '1.0') {
      args.add('pressScale: ${_num(_pressScale)}');
    }
    args.add('onTap: () {}');
    return 'LiquidFab(\n  ${args.join(',\n  ')},\n)';
  }

  void _pickPreset(String name) {
    final s = _presets[name]!;
    setState(() {
      _preset = name;
      _haloOpacity = s.haloOpacity;
      _elevation = s.elevation;
      _glossOpacity = s.glossOpacity;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('liquid_fab')),
      floatingActionButton: LiquidFab(
        style: _style,
        open: _open,
        semanticLabel: 'Open the demo panel',
        openSemanticLabel: 'Close the demo panel',
        onTap: () => setState(() => _open = !_open),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 860;
          final stage = _Stage(
            dark: _darkStage,
            child: LiquidFab(
              style: _style,
              diameter: _diameter,
              open: _open,
              loopDuration: Duration(
                milliseconds: (_loopSeconds * 1000).round(),
              ),
              playing: _playing,
              visible: _visible,
              respectReduceMotion: _respectReduceMotion,
              enableHaptics: _haptics,
              hoverScale: _hoverScale,
              pressScale: _pressScale,
              tooltip: 'Tap to toggle open',
              onTap: () => setState(() => _open = !_open),
            ),
          );
          final controls = _controls(theme);
          final code = _CodePanel(code: _code);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Presets', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final e in _presets.entries)
                    _PresetTile(
                      name: e.key,
                      style: e.value,
                      selected: e.key == _preset,
                      onTap: () => _pickPreset(e.key),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              Text('Playground', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              if (wide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        children: [stage, const SizedBox(height: 16), code],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(child: controls),
                  ],
                )
              else ...[
                stage,
                const SizedBox(height: 16),
                controls,
                const SizedBox(height: 16),
                code,
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _controls(ThemeData theme) => Column(
    children: [
      _slider('Diameter', _diameter, 32, 120, (v) => _diameter = v),
      _slider('Loop (s)', _loopSeconds, 2, 20, (v) => _loopSeconds = v),
      _slider('Breath', _breath, 0, 0.1, (v) => _breath = v),
      _slider('Wave depth ×', _waveScale, 0, 8, (v) => _waveScale = v),
      _slider('Core ratio', _core, 0.7, 1, (v) => _core = v),
      _slider('Halo opacity', _haloOpacity, 0, 1, (v) => _haloOpacity = v),
      _slider('Halo blur', _haloBlur, 0, 40, (v) => _haloBlur = v),
      _slider('Elevation', _elevation, 0, 30, (v) => _elevation = v),
      _slider('Gloss', _glossOpacity, 0, 1, (v) => _glossOpacity = v),
      _slider('Rim width', _rimWidth, 0, 4, (v) => _rimWidth = v),
      _slider('Hover light', _hoverLight, 0, 0.3, (v) => _hoverLight = v),
      _slider('Press dark', _pressDark, 0, 0.4, (v) => _pressDark = v),
      _slider('Hover scale', _hoverScale, 1, 1.3, (v) => _hoverScale = v),
      _slider('Press scale', _pressScale, 0.7, 1, (v) => _pressScale = v),
      Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          _chip('Playing', _playing, (v) => _playing = v),
          _chip('Open', _open, (v) => _open = v),
          _chip('Visible', _visible, (v) => _visible = v),
          _chip('Shadow', _shadow, (v) => _shadow = v),
          _chip('Gloss', _gloss, (v) => _gloss = v),
          _chip('Haptics', _haptics, (v) => _haptics = v),
          _chip(
            'Respect reduce motion',
            _respectReduceMotion,
            (v) => _respectReduceMotion = v,
          ),
          _chip('Dark stage', _darkStage, (v) => _darkStage = v),
        ],
      ),
    ],
  );

  Widget _slider(
    String label,
    double value,
    double min,
    double max,
    void Function(double) set,
  ) => Row(
    children: [
      SizedBox(width: 120, child: Text(label)),
      Expanded(
        child: Slider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          onChanged: (v) => setState(() => set(v)),
        ),
      ),
      SizedBox(
        width: 48,
        child: Text(
          value.toStringAsFixed(max <= 1.3 ? 3 : 1),
          textAlign: TextAlign.end,
        ),
      ),
    ],
  );

  Widget _chip(String label, bool value, void Function(bool) set) => FilterChip(
    label: Text(label),
    selected: value,
    onSelected: (v) => setState(() => set(v)),
  );
}

class _Stage extends StatelessWidget {
  const _Stage({required this.dark, required this.child});

  final bool dark;
  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 250),
    height: 280,
    decoration: BoxDecoration(
      color: dark ? const Color(0xFF15171A) : const Color(0xFFF6F3EE),
      borderRadius: BorderRadius.circular(16),
    ),
    alignment: Alignment.center,
    child: child,
  );
}

/// The Dart for the current settings, with a copy button.
class _CodePanel extends StatelessWidget {
  const _CodePanel({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Code', style: Theme.of(context).textTheme.titleSmall),
              const Spacer(),
              TextButton.icon(
                icon: const Icon(Icons.copy_rounded, size: 18),
                label: const Text('Copy'),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: code));
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      const SnackBar(content: Text('Copied to the clipboard')),
                    );
                },
              ),
            ],
          ),
          SelectableText(
            code,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontFamilyFallback: ['Menlo', 'Consolas', 'Courier New'],
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _PresetTile extends StatelessWidget {
  const _PresetTile({
    required this.name,
    required this.style,
    required this.selected,
    required this.onTap,
  });

  final String name;
  final LiquidFabStyle style;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 132,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected ? scheme.primary : scheme.outlineVariant,
          width: selected ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          LiquidFab(
            style: style,
            diameter: 56,
            semanticLabel: 'Use the $name preset',
            onTap: onTap,
          ),
          const SizedBox(height: 4),
          Text(name, style: Theme.of(context).textTheme.labelMedium),
        ],
      ),
    );
  }
}
