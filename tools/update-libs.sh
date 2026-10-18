#!/usr/bin/env bash
# Refreshes the embedded third-party libraries in QualityOfLifeForever/Libs.
# Libraries are copied unmodified (their licenses require it); only files the
# client doesn't load (tests, tooling, standalone .toc, README) are left out.
set -euo pipefail

LIBEDITMODE_TAG="18"

root="$(cd "$(dirname "$0")/.." && pwd)"
libs="$root/QualityOfLifeForever/Libs"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

git -c advice.detachedHead=false clone -q --depth 1 --branch "$LIBEDITMODE_TAG" https://github.com/p3lim-wow/LibEditMode.git "$tmp/LibEditMode"
rm -rf "$libs/LibEditMode"
mkdir -p "$libs/LibEditMode"
cp -r "$tmp/LibEditMode/"{LICENSE.txt,LibEditMode.lua,namespaced.lua,pools.lua,embed.xml,widgets} "$libs/LibEditMode/"

echo "LibEditMode $LIBEDITMODE_TAG -> $libs/LibEditMode"
