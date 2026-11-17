#!/usr/bin/env bash
# Builds the example for the web and publishes it to the repository's
# gh-pages branch, served at https://rudraveersandhu.github.io/liquid-fab/.
set -euo pipefail

cd "$(dirname "$0")/.."
remote="${1:-https://github.com/rudraveersandhu/liquid-fab.git}"

flutter build web --release --base-href /liquid-fab/

site="$(mktemp -d)"
trap 'rm -rf "$site"' EXIT
cp -R build/web/. "$site/"
touch "$site/.nojekyll" # serve Flutter's files as they are

git -C "$site" init -q -b gh-pages
git -C "$site" add -A
git -C "$site" commit -qm "Deploy the liquid_fab live demo"
git -C "$site" push -f "$remote" gh-pages:gh-pages
