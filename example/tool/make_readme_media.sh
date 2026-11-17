#!/usr/bin/env bash
# Regenerates doc/presets.gif and doc/playground.png for the README.
# Needs flutter and ffmpeg on PATH. Run from anywhere.
set -euo pipefail

cd "$(dirname "$0")/.."
flutter_root="$(cd "$(dirname "$(command -v flutter)")/.." && pwd)"
export FONTS_DIR="$flutter_root/bin/cache/artifacts/material_fonts"

rm -rf build/readme_media
flutter test tool/readme_media_test.dart

# One seamless loop at 20 fps, with a palette tuned to the frames.
ffmpeg -loglevel error -y -framerate 20 \
  -i build/readme_media/frames/frame_%03d.png \
  -vf "scale=iw/2:-1:flags=lanczos,split[a][b];[a]palettegen=max_colors=256:stats_mode=full[p];[b][p]paletteuse=dither=sierra2_4a" \
  -loop 0 ../doc/presets.gif

ls -lh ../doc/presets.gif ../doc/playground.png
