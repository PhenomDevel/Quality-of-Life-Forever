#!/usr/bin/env bash
# Refreshes the embedded third-party libraries in QualityOfLifeForever/Libs.
# Libraries are copied unmodified (their licenses require it); only files the
# client doesn't load (tests, tooling, standalone .toc, README) are left out.
# LibStub, CallbackHandler, LibDataBroker and LibDBIcon are git-ignored
# (.pkgmeta externals in release builds); this fetches them for local dev.
# Ace3's GitHub repository carries the same files as its CurseForge SVN trunk;
# LibDBIcon is read straight from its SVN trunk over HTTPS.
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

git clone -q --depth 1 https://github.com/WoWUIDev/Ace3.git "$tmp/Ace3"
git clone -q --depth 1 https://github.com/tekkub/libdatabroker-1-1.git "$tmp/LibDataBroker"
rm -rf "$libs/LibStub" "$libs/CallbackHandler-1.0" "$libs/LibDataBroker-1.1" "$libs/LibDBIcon-1.0"
mkdir -p "$libs/LibDataBroker-1.1" "$libs/LibDBIcon-1.0"
cp -r "$tmp/Ace3/LibStub" "$tmp/Ace3/CallbackHandler-1.0" "$libs/"
cp "$tmp/LibDataBroker/LibDataBroker-1.1.lua" "$libs/LibDataBroker-1.1/"
curl -fsSL -o "$libs/LibDBIcon-1.0/LibDBIcon-1.0.lua" https://repos.curseforge.com/wow/libdbicon-1-0/trunk/LibDBIcon-1.0/LibDBIcon-1.0.lua

echo "LibEditMode $LIBEDITMODE_TAG, Ace3 $(git -C "$tmp/Ace3" rev-parse --short HEAD), LibDataBroker, LibDBIcon -> $libs"
