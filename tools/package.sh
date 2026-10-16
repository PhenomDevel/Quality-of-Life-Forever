#!/usr/bin/env bash
# Builds an installable zip in .release/.
#
#   tools/package.sh            version from `git describe` (e.g. v0.1.0-3-gabc123)
#   tools/package.sh 1.2.3      explicit version
set -euo pipefail

ADDON="QualityOfLifeForever"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VERSION="${1:-$(git -C "$ROOT" describe --tags --always --dirty 2>/dev/null || echo dev)}"
OUT="$ROOT/.release"
STAGE="$OUT/stage"

rm -rf "$STAGE"
mkdir -p "$STAGE"
cp -R "$ROOT/$ADDON" "$STAGE/$ADDON"

# Replace the packager token used in the .toc and Lua files.
grep -rl "@project-version@" "$STAGE/$ADDON" | while read -r file; do
	sed -i.bak "s/@project-version@/$VERSION/g" "$file" && rm -f "$file.bak"
done

ZIP="$OUT/$ADDON-$VERSION.zip"
rm -f "$ZIP"
(cd "$STAGE" && zip -qr "$ZIP" "$ADDON")
rm -rf "$STAGE"
echo "$ZIP"
