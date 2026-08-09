# photo-assets

Afilmory（afilmory.art）SaaS "Add storage provider → GitHub" 的存储仓库，GitHub 仓库 `thedavidweng/photo-assets`（private），本目录为本地工作副本。afilmory.art 后台已配置读取。

## 目录结构

```
public/photos/          ← 照片根目录（SaaS path 字段 = "public/photos"）
    ├── 2025-04-08/     ← 一层目录 = 一个 tag，tag 统一为拍摄日期
    │   └── DSC02230.avif
    └── 2025-02-03/
        └── DSC02369.avif
```

- **tag = 日期**：一层目录即一个 tag，统一 `YYYY-MM-DD` 格式，无语义名
- **事件名不进 tag**：事件归类写在图片 XMP `dc:Subject`（如 `balloon`、`gala`），个人分类用 exiftool 按 Subject 过滤；Afilmory 不读它
- 文件名保留相机原名（`DSCFxxxx`）；必须保留 `DateTimeOriginal`（画廊排序依据）
- 生成流程与参数：见 `docs/avif-photography-best-practice.md`（Sharp 统一管线，批量命令 `scripts/sharp-avif.mjs`，清单 `import-manifest.tsv`）

## Afilmory 行为规则（以源码为准，勿在本 README 复制结论）

后端（含 SaaS）复用开源仓库 [Afilmory/Afilmory](https://github.com/Afilmory/Afilmory) 的 `packages/builder`，规则一律读该库源码：

| 规则 | 源码位置 |
|---|---|
| 支持格式白名单（收录/不收录） | `packages/builder/src/constants/index.ts`（`SUPPORTED_FORMATS`） |
| tag 从路径提取（每层目录=一个 tag，无层级） | `packages/builder/src/photo/info-extractor.ts` |
| photoId 生成（文件名+摘要，改名即换 id） | `packages/builder/src/photo/image-pipeline.ts`（`generatePhotoId`） |
| Live Photo 配对规则（同目录同名 .mov/.mp4） | `packages/builder/src/photo/live-photo-handler.ts` |
| GitHub provider 同步/Git LFS/raw URL | `packages/builder/src/storage/providers/github-provider.ts` |
| 缩略图/EXIF/排序/架构总览 | `packages/builder/src/photo/`、仓库 `docs/` |

上线前核对产物是否满足规则（尤其 `SUPPORTED_FORMATS`），以源码为准。

## afilmory.art 配置映射

```
owner:   thedavidweng
repo:    photo-assets
branch:  main
path:    public/photos
token:   后台创建（Contents: Read；需 SaaS CMS 改删回写则 Contents: Write）
customDomain: 不填（默认 raw.githubusercontent.com）；国内访问慢可填 cdn.jsdelivr.net/gh/thedavidweng/photo-assets@main
```

## Agent 操作指引

1. 照片放进 `public/photos/<YYYY-MM-DD>/` 下（转换见 `docs/avif-photography-best-practice.md`）
2. `git add -A && git commit && git push` 到 `main`
3. afilmory.art 后台触发/等待同步即可