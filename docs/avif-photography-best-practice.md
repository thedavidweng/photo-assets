# AVIF 摄影批产执行手册（体积优先 · Sharp 统一管线）

实测定档：2026-08。适用：摄影画廊离线批产，画质优先、体积要小。

## 1. 管线

```
RAW ──sips（仅 decode，禁 -r）──► PNG ──► Sharp .autoOrient().keepExif() ──► exiftool 删方向 ──► .avif
JPG ──────────────────────────────► Sharp .autoOrient().keepExif() ──► exiftool 删方向 ──► .avif
```

- 编码器：Sharp（libheif），无第二条
- sips 只管 RAW decode；方向、编码、metadata 选择一律 Sharp
- 方向原则：进编码前像素已烘焙旋转；成片无任何方向标记（EXIF/IFD1/XMP 三层均无）
- 两条路径终点相同：统一 exiftool 一句收尾

## 2. 定案参数

| 项 | 值 | 说明 |
|---|---|---|
| 质量 | `quality: 60, effort: 6` | Sharp 刻度；8-bit、**`4:2:0` 必须显式**（sharp 默认 4:4:4，实测） |
| 速度 | 默认即可 | effort 4 体积仅 ~3% 差异 |

## 3. metadata（实测，勿依赖 API 语义推断）

| 路径 | metadata 处理 | exiftool |
|---|---|---|
| JPG → Sharp | `autoOrient().keepExif()`：13 个关键 tag 全量保留，方向归一 | 删方向三层 |
| RAW → sips PNG → Sharp | sips PNG 自带全量 EXIF（与 ARW 源逐一相同），Sharp 透传 | 删方向三层 |

- 13 tag：`DateTimeOriginal / Make / Model / LensModel / FNumber / ExposureTime / ISO / FocalLength / FocalLengthIn35mmFilm / Aperture / WhiteBalance / SceneCaptureType / Software`
- `keepExif()` = 保留 EXIF、丢弃 XMP——XMP `tiff:Orientation` 在源头不进入输出（实测），比事后删除更稳
- `withMetadata()` / `keepMetadata()` 会带 XMP 进输出，sips PNG 输入时残留方向（实测），勿用
- **metadata 以实际输出 exiftool 验证为准**，不依赖 Sharp 的"全保留"语义

## 4. 执行

```bash
# 单文件（auto：扩展名自动判定 RAW/JPG）
node scripts/sharp-avif.mjs <in> <out.avif> 60

# 批量
find <src> -type f \( -iname '*.arw' -o -iname '*.jpg' \) | while read f; do
  node scripts/sharp-avif.mjs "$f" "${f%.*}.avif" 60
done
```

依赖：macOS、Node+sharp、sips、exiftool。

### 4.1 事件名写 XMP Subject（SOP）

tag 一律用日期目录（见 §7 仓库规则），事件名不建目录，写入图片 XMP `dc:Subject` 便于个人分类（Afilmory 不读取该字段，仅本机工具按 Subject 过滤时用）：

```bash
# 转换完成后补写（事件名每张必写，勿省略）
exiftool -q -overwrite_original "-XMP-dc:Subject+=<事件名>" <out.avif>
```

- 已入库事件名：`balloon`／`cherry-blossom`／`tulip`／`tyler-concert`／`gala`（新事件命名沿用一词风格）
- 实测（2026-08）：IPTC:Keywords 在 AVIF 上写入无效，勿用；XMP 追加后方向三层仍为空，无副作用
- 写入在删除方向标记之后执行，且不新增 Orientation；每次补写后按 §5 验证

## 5. 验证（每批抽检）

```bash
avifdec out.avif /dev/null    # Transformations: None
exiftool -G1 -s -s \
  -EXIF:Orientation \
  -IFD1:Orientation \
  -XMP-tiff:Orientation \
  out.avif                    # 三层全部为空
exiftool -s -s -s -DateTimeOriginal -Make -Model out.avif   # 有值
```

- IFD1 = JPG 缩略图 IFD，会自带一份方向标记；`-Orientation=` 删不到它，必须显式 `-IFD1:Orientation=`（实测）
- 方向错误经典错因：sips `-r` + autoOrient 二次旋转

## 6. 上游坑（已上报，复现时别重复调查）

- exiftool #459：`-Orientation=1` 数字赋值静默错写为 3；字符串赋值正常
- sharp #4585：autoOrient 不碰 XMP `tiff:Orientation`——已用 `keepExif()` 从源头规避
- `withMetadata({orientation: undefined})`  ≠ 删除 Orientation（实测无效），勿用

## 7. 仓库规则（Afilmory）

- `public/photos/<YYYY-MM-DD>/`（日期目录 = tag，无语义目录；事件名只写 XMP `dc:Subject`，见 §4.1）
- 文件名保留相机原名（改动生成新 photoId，URL 失效）；必须保留 `DateTimeOriginal`（画廊排序依据）
- Live Photo：同名 `.mov`/`.mp4` 同目录
- 单文件 ≤100MB、仓库 ≤1GB、禁 LFS、`path` = `public/photos`