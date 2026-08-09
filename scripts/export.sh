#!/bin/bash
# export.sh <src> <out> <fmt> [q] [extra-avifenc-args]
# fmt: webp | avif    q default: webp=90, avif=62
# sips 解码（含 EXIF 方向烘焙）→ 编码 → exiftool 从源拷关键 EXIF，Orientation 删（像素已烘焙）
src="$1"; out="$2"; fmt="$3"
q="${4:-}"; extra="$5"
deg=$(exiftool -s -s -s -Orientation "$src")
case "$deg" in
  "Rotate 90 CW")  rot="-r 90" ;;
  "Rotate 180")    rot="-r 180" ;;
  "Rotate 270 CW") rot="-r 270" ;;
  *) rot="" ;;
esac
if [ "$fmt" = "webp" ]; then
  [ -z "$q" ] && q=90
  tmp="${out}.tmp.png"
  sips $rot -s format png "$src" --out "$tmp" 2>&1
  cwebp -quiet -q "$q" -preset photo "$tmp" -o "$out"
  rm -f "$tmp"
else
  [ -z "$q" ] && q=62
  tmp="${out}.tmp.png"
  sips $rot -s format png "$src" --out "$tmp" 2>&1
  avifenc -q "$q" -d 8 -y 420 $extra "$tmp" -o "$out" 2>/dev/null
  rm -f "$tmp"
fi
tags=(-DateTimeOriginal -CreateDate -ModifyDate -Make -Model -LensModel -LensMake -FNumber -ExposureTime -ISO -FocalLength -FocalLengthIn35mmFilm -Flash -Aperture -WhiteBalance -SceneCaptureType -Software)
exiftool -q -m -overwrite_original -tagsFromFile "$src" "${tags[@]}" -Orientation= "$out" 2>/dev/null