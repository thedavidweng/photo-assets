#!/bin/bash
# convert-fulljpeg.sh — FULL-JPEG 全部转 AVIF 入库 + dc:Subject（bash 3.2 兼容，无关联数组）
set -u
SRC=/Users/david/Pictures/FULL-JPEG
DEST=/Users/david/Pictures/photo-assets/public/photos
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

event_of() {
  case "$1" in
    2025-04-24) echo "Abbotsford Tulip Festival" ;;
    2025-04-04) echo "Cherry blossom season" ;;
    2025-04-13) echo "Yap Sakura" ;;
    2025-11-01) echo "coraline-cosplay" ;;
    2025-04-26) echo "Notion Career Gala" ;;
    2025-02-28) echo "Tyler, The Creator - CHROMAKOPIA: THE WORLD TOUR" ;;
    2025-02-16) echo "Trip to San Francisco" ;;
    2025-02-17) echo "Trip to San Francisco" ;;
    *) echo "" ;;
  esac
}

ok=0
fail=0
skip=0
for jpg in "$SRC"/*.jpg; do
  base=$(basename "$jpg" .jpg)
  date=$(exiftool -m -d '%Y-%m-%d' -DateTimeOriginal -s3 "$jpg" 2>/dev/null)
  [ -z "$date" ] && date="unknown"
  dir="$DEST/$date"
  mkdir -p "$dir"
  out="$dir/$base.avif"
  if [ -f "$out" ]; then
    skip=$((skip+1))
    echo "SKIP $date $base"
    continue
  fi
  if node "$SCRIPT_DIR/sharp-avif.mjs" "$jpg" "$out" 60 auto >/dev/null 2>&1; then
    subj=$(event_of "$date")
    if exiftool -q -m -overwrite_original "-XMP-dc:Subject=$subj" "$out" >/dev/null 2>&1; then
      ok=$((ok+1))
      echo "OK  $date $base"
    else
      fail=$((fail+1))
      echo "SUBJECT_FAIL $date $base"
    fi
  else
    fail=$((fail+1))
    echo "CONVERT_FAIL $date $base"
  fi
done
echo "=== done: ok=$ok fail=$fail skip=$skip ==="