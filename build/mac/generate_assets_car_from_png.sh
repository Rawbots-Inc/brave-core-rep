#!/usr/bin/env bash
set -euo pipefail

# Generate a macOS Assets.car (app icon asset catalog) from a single 1024x1024 PNG,
# and install it into Brave's theme paths so the built .app/.dmg show the new icon.
#
# Requirements:
# - macOS
# - Xcode Command Line Tools (for xcrun/actool)
# - sips (built-in on macOS)
#
# Usage:
#   build/mac/generate_assets_car_from_png.sh --png /abs/path/icon.png [--channel beta|nightly|development|dev] [--min-os 11.0]
#
# Notes:
# - For stable/release, omit --channel to write to app/theme/brave/mac/Assets.car.
# - For channel builds, writes to app/theme/brave/mac/<channel>/Assets.car.
# - Also writes into the sibling Chromium tree at ../chrome/app/theme/brave/mac/... (if it exists).

usage() {
  cat <<'EOF'
Usage:
  build/mac/generate_assets_car_from_png.sh --png /abs/path/icon.png [--channel <name>] [--min-os <ver>]

Options:
  --png       Absolute path to a 1024x1024 PNG.
  --channel   Optional: beta|nightly|development|dev (omit for stable).
  --min-os    Optional: deployment target for actool (default: 11.0).
EOF
}

PNG=""
CHANNEL=""
MIN_OS="11.0"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --png)
      PNG="${2:-}"; shift 2;;
    --channel)
      CHANNEL="${2:-}"; shift 2;;
    --min-os)
      MIN_OS="${2:-}"; shift 2;;
    -h|--help)
      usage; exit 0;;
    *)
      echo "Unknown argument: $1" >&2
      usage
      exit 2
      ;;
  esac
done

if [[ -z "$PNG" ]]; then
  echo "Missing --png" >&2
  usage
  exit 2
fi

if [[ ! -f "$PNG" ]]; then
  echo "PNG not found: $PNG" >&2
  exit 2
fi

if ! command -v xcrun >/dev/null 2>&1; then
  echo "xcrun not found. Install Xcode Command Line Tools: xcode-select --install" >&2
  exit 2
fi

if ! command -v sips >/dev/null 2>&1; then
  echo "sips not found (unexpected on macOS)." >&2
  exit 2
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BRAVE_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

WORK_DIR="$(mktemp -d 2>/dev/null || mktemp -d -t brave_assets_car)"
trap 'rm -rf "$WORK_DIR"' EXIT

APPICONSET="$WORK_DIR/Assets.xcassets/AppIcon.appiconset"
mkdir -p "$APPICONSET"

# Generate icon PNGs.
# Expect source to be 1024x1024; sips will scale down as needed.
scale() {
  local w="$1"; local h="$2"; local out="$3"
  sips -z "$h" "$w" "$PNG" --out "$out" >/dev/null
}

scale 16 16   "$APPICONSET/icon_16x16.png"
scale 32 32   "$APPICONSET/icon_16x16@2x.png"
scale 32 32   "$APPICONSET/icon_32x32.png"
scale 64 64   "$APPICONSET/icon_32x32@2x.png"
scale 128 128 "$APPICONSET/icon_128x128.png"
scale 256 256 "$APPICONSET/icon_128x128@2x.png"
scale 256 256 "$APPICONSET/icon_256x256.png"
scale 512 512 "$APPICONSET/icon_256x256@2x.png"
scale 512 512 "$APPICONSET/icon_512x512.png"
cp "$PNG" "$APPICONSET/icon_512x512@2x.png"

cat > "$APPICONSET/Contents.json" <<'JSON'
{
  "images" : [
    { "idiom" : "mac", "size" : "16x16",   "scale" : "1x", "filename" : "icon_16x16.png" },
    { "idiom" : "mac", "size" : "16x16",   "scale" : "2x", "filename" : "icon_16x16@2x.png" },
    { "idiom" : "mac", "size" : "32x32",   "scale" : "1x", "filename" : "icon_32x32.png" },
    { "idiom" : "mac", "size" : "32x32",   "scale" : "2x", "filename" : "icon_32x32@2x.png" },
    { "idiom" : "mac", "size" : "128x128", "scale" : "1x", "filename" : "icon_128x128.png" },
    { "idiom" : "mac", "size" : "128x128", "scale" : "2x", "filename" : "icon_128x128@2x.png" },
    { "idiom" : "mac", "size" : "256x256", "scale" : "1x", "filename" : "icon_256x256.png" },
    { "idiom" : "mac", "size" : "256x256", "scale" : "2x", "filename" : "icon_256x256@2x.png" },
    { "idiom" : "mac", "size" : "512x512", "scale" : "1x", "filename" : "icon_512x512.png" },
    { "idiom" : "mac", "size" : "512x512", "scale" : "2x", "filename" : "icon_512x512@2x.png" }
  ],
  "info" : { "author" : "xcode", "version" : 1 }
}
JSON

OUT_DIR="$WORK_DIR/compiled"
mkdir -p "$OUT_DIR"

PARTIAL_PLIST="$OUT_DIR/assetcatalog_generated_info.plist"
ACTOOL_LOG="$OUT_DIR/actool.log"

set +e
xcrun actool \
  --output-format human-readable-text \
  --notices --warnings --errors \
  --platform macosx \
  --target-device mac \
  --minimum-deployment-target "$MIN_OS" \
  --app-icon AppIcon \
  --output-partial-info-plist "$PARTIAL_PLIST" \
  --compile "$OUT_DIR" \
  "$WORK_DIR/Assets.xcassets" 2>&1 | tee "$ACTOOL_LOG"
ACTOOL_EXIT=${PIPESTATUS[0]}
set -e

if [[ $ACTOOL_EXIT -ne 0 ]]; then
  echo "actool failed (exit $ACTOOL_EXIT). See: $ACTOOL_LOG" >&2
  exit $ACTOOL_EXIT
fi

ASSETS_CAR="$OUT_DIR/Assets.car"
if [[ ! -f "$ASSETS_CAR" ]]; then
  echo "actool did not produce Assets.car. See: $ACTOOL_LOG" >&2
  exit 1
fi

# Determine target directory for brave-side theme.
BRAVE_THEME_DIR="$BRAVE_ROOT/app/theme/brave/mac"
if [[ -n "$CHANNEL" ]]; then
  BRAVE_THEME_DIR="$BRAVE_THEME_DIR/$CHANNEL"
fi

mkdir -p "$BRAVE_THEME_DIR"
cp "$ASSETS_CAR" "$BRAVE_THEME_DIR/Assets.car"

# Also update the sibling Chromium tree if present.
CHROME_THEME_DIR="$BRAVE_ROOT/../chrome/app/theme/brave/mac"
if [[ -n "$CHANNEL" ]]; then
  CHROME_THEME_DIR="$CHROME_THEME_DIR/$CHANNEL"
fi

if [[ -d "$BRAVE_ROOT/../chrome" ]]; then
  mkdir -p "$CHROME_THEME_DIR"
  cp "$ASSETS_CAR" "$CHROME_THEME_DIR/Assets.car"
fi

echo "Wrote Assets.car to: $BRAVE_THEME_DIR/Assets.car"
if [[ -d "$BRAVE_ROOT/../chrome" ]]; then
  echo "Wrote Assets.car to: $CHROME_THEME_DIR/Assets.car"
fi

echo "SHA256 (new Assets.car):"
shasum -a 256 "$BRAVE_THEME_DIR/Assets.car" | cat
