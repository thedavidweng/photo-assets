#!/usr/bin/env node
// sharp-avif.mjs <in> <out.avif> [q] [fmt]
// fmt: auto | jpg | raw    q 默认 60（Sharp/libheif 刻度）
import sharp from 'sharp'
import { execFileSync } from 'node:child_process'

const [inFile, outFile, q = 60, fmt = 'auto'] = process.argv.slice(2)
const rawPattern = /\.(arw|cr2|cr3|nef|dng|orf|raf|rw2)$/i
const isRaw = fmt === 'raw' || (fmt === 'auto' && rawPattern.test(inFile))

try {
  if (isRaw) {
    // RAW：sips 仅 decode（禁 -r）。方向/编码由 Sharp 统一处理
    const tmp = `${outFile}.tmp.png`
    execFileSync('sips', ['-s', 'format', 'png', inFile, '--out', tmp], { stdio: 'ignore' })
    await sharp(tmp)
      .autoOrient()
      .keepExif() // 只保留 EXIF；丢弃 XMP，XMP tiff:Orientation 不进入输出
      .avif({ quality: +q, effort: 6, chromaSubsampling: '4:2:0' })
      .toFile(outFile)
    execFileSync('rm', ['-f', tmp])
  } else {
    await sharp(inFile)
      .autoOrient()
      .keepExif()
      .avif({ quality: +q, effort: 6, chromaSubsampling: '4:2:0' })
      .toFile(outFile)
  }
  // 方向标记三层全删：EXIF IFD0 / IFD1（JPG 缩略图）/ XMP。像素已烘焙，成片无任何方向标记
  execFileSync('exiftool', ['-q', '-m', '-overwrite_original',
    '-EXIF:Orientation=', '-IFD1:Orientation=', '-XMP-tiff:Orientation=', outFile], { stdio: 'ignore' })
  console.log(`ok ${outFile} (${isRaw ? 'sips+sharp' : 'sharp'})`)
} catch (e) {
  console.error('FAIL:', e.message)
  process.exit(1)
}