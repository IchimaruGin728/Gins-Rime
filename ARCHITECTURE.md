# Gins-Rime Architecture

## Overview

Gins-Rime 是基于核心引擎（core）的个人定制 RIME 输入方案，覆盖 macOS（鼠须管 Squirrel）和 iOS（元书 Hamster v3）双平台。

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          Gins-Rime Architecture                             │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   ┌─────────────────────── Upstream Sources ───────────────────────┐        │
│   │                                                                 │        │
│   │  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────┐  │        │
│   │  │  核心引擎      │  │  雾凇拼音      │  │  萌娘百科词库        │  │        │
│   │  │  (core)   │  │  (rime-ice)  │  │  (moetype)          │  │        │
│   │  │              │  │              │  │                      │  │        │
│   │  │ • base schema │  │ • melt_eng   │  │ • tone_moe.dict.yaml │  │        │
│   │  │ • 200M 语法模型 │  │   混输翻译器    │  │ • ACG 专有名词       │  │        │
│   │  │ • 各类词库      │  │ • en_dicts   │  │                      │  │        │
│   │  └──────┬───────┘  └──────┬───────┘  └──────────┬───────────┘  │        │
│   │         │                 │                      │              │        │
│   └─────────┼─────────────────┼──────────────────────┼──────────────┘        │
│             │                 │                      │                       │
│   ┌─────────┼─────── Build Pipeline ────────────────┼──────────────┐        │
│   │         │                 │                      │              │        │
│   │         │     ┌───────────────────────┐          │              │        │
│   │         │     │   zhwiki-builder      │          │              │        │
│   │         │     │   (Rust CLI)          │          │              │        │
│   │         │     │                       │          │              │        │
│   │         │     │  titles.gz → 逐行过滤  │          │              │        │
│   │         │     │  → OpenCC T2S+S2SG    │          │              │        │
│   │         │     │  → rayon 并行拼音      │          │              │        │
│   │         │     │  → zhwiki.dict.yaml   │          │              │        │
│   │         │     └───────────┬───────────┘          │              │        │
│   │         │                 │                      │              │        │
│   │         ▼                 ▼                      ▼              │        │
│   │  ┌─────────────────────────────────────────────────────┐       │        │
│   │  │                  gins.dict.yaml                      │       │        │
│   │  │                                                      │       │        │
│   │  │  import_tables:                                      │       │        │
│   │  │    - core dicts  (核心核心词库)                    │       │        │
│   │  │    - zhwiki          (维基百科词库 · Rust build)       │       │        │
│   │  │    - tone_moe        (萌娘百科词库)                    │       │        │
│   │  │    - gins-shici      (古诗词补充)                      │       │        │
│   │  └─────────────────────────────────────────────────────┘       │        │
│   │                           │                                     │        │
│   │                           ▼                                     │        │
│   │  ┌─────────────────────────────────────────────────────┐       │        │
│   │  │              gins.schema.yaml (patch)                │       │        │
│   │  │  __include: core.schema:/                        │       │        │
│   │  │  __patch:                                            │       │        │
│   │  │    schema_id: gins                                   │       │        │
│   │  │    translator/dictionary: gins                       │       │        │
│   │  └─────────────────────────────────────────────────────┘       │        │
│   │                                                                 │        │
│   │  ┌─────────────────────────────────────────────────────┐       │        │
│   │  │              gins.custom.yaml (patch)                │       │        │
│   │  │    table_translator@gins_eng   (英文词库)              │       │        │
│   │  │    table_translator@gins_cn_en (中英混输)              │       │        │
│   │  └─────────────────────────────────────────────────────┘       │        │
│   │                                                                 │        │
│   └─────────────────────────────────────────────────────────────────┘        │
│                                                                             │
│   ┌───────────────────── Platform Targets ──────────────────────┐           │
│   │                                                              │           │
│   │  ┌─────────────────────┐    ┌──────────────────────────┐    │           │
│   │  │  macOS · 鼠须管       │    │  iOS · 元书 (Hamster v3)  │    │           │
│   │  │  (Squirrel)         │    │                          │    │           │
│   │  │                     │    │  scheme/hamster/          │    │           │
│   │  │  scheme/squirrel/   │    │  ├── hamster.custom.yaml  │    │           │
│   │  │  ├── squirrel.custom│    │  ├── scripts/            │    │           │
│   │  │  │   .yaml          │    │  │   └── *.js            │    │           │
│   │  │  └── default.custom │    │  └── skins/             │    │           │
│   │  │      .yaml          │    │      └── *.jsonnet        │    │           │
│   │  │                     │    │                          │    │           │
│   │  │  gins-rime CLI      │    │  iCloud / Git 同步        │    │           │
│   │  │  (Swift CLI)        │    │                          │    │           │
│   │  │  ├── deploy         │    │                          │    │           │
│   │  │  ├── update         │    │                          │    │           │
│   │  │  ├── sync           │    │                          │    │           │
│   │  │  └── status         │    │                          │    │           │
│   │  └─────────────────────┘    └──────────────────────────┘    │           │
│   │                                                              │           │
│   └──────────────────────────────────────────────────────────────┘           │
│                                                                             │
│   ┌───────────────── Infrastructure (GitHub + Cloudflare) ──────────┐       │
│   │                                                                  │       │
│   │  GitHub Actions                    Cloudflare                    │       │
│   │  ┌─────────────────────┐          ┌─────────────────────────┐   │       │
│   │  │ build-zhwiki.yml    │          │  workers/gins-rime       │   │       │
│   │  │  cron: 每月2号       │          │  • GET /version          │   │       │
│   │  │  → Rust build       │          │  • GET /api/status       │   │       │
│   │  │  → R2 upload        │          │  • GET /dicts/{name}     │   │       │
│   │  │                     │          │  • POST /workflow/...    │   │       │
│   │  │ build-shici.yml     │          │  • GET  /* (static site) │   │       │
│   │  │  → poetry dedup     │          │                          │   │       │
│   │  │  → R2 upload        │          │  Workflows               │   │       │
│   │  │                     │          │  • DictUpdateWorkflow    │   │       │
│   │  │ release.yml         │          │                          │   │       │
│   │  │  → scheme packaging │          │  Queues                  │   │       │
│   │  │  → Swift CLI build  │          │  • gins-rime-builds      │   │       │
│   │  │  → R2 + GH Release  │          │                          │   │       │
│   │  │                     │          │  R2: gins-rime            │   │       │
│   │  │ sync-upstream.yml   │          │  • dicts/                │   │       │
│   │  │  → core/rime-ice│          │  • releases/             │   │       │
│   │  │  → moetype → R2     │          │  • cli/                  │   │       │
│   │  │  → chinese-poetry   │          └─────────────────────────┘   │       │
│   │  └─────────────────────┘                                         │       │
│   │                                                                  │       │
│   └──────────────────────────────────────────────────────────────────┘       │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Data Flow

```
                    ┌──────────────────────────────────┐
                    │       GitHub Actions (cron)       │
                    └──────────┬───────────────────────┘
                               │
              ┌────────────────┼────────────────┐
              ▼                ▼                ▼
    ┌─────────────────┐ ┌───────────┐  ┌──────────────┐
    │  zhwiki titles   │ │ moetype   │  │  rime-ice    │
    │  (Rust builder)  │ │ (release) │  │  (git clone) │
    └────────┬────────┘ └─────┬─────┘  └──────┬───────┘
             │                │               │
             ▼                ▼               ▼
    ┌─────────────────────────────────────────────────┐
    │              R2: gins-rime bucket                │
    │         dicts/ · releases/ · cli/                │
    └────────────────────┬────────────────────────────┘
                         │
          ┌──────────────┼──────────────┐
          ▼                             ▼
    ┌───────────────┐          ┌──────────────────┐
    │ gins-rime CLI │          │ 元书 Hamster v3  │
    │ (Swift · macOS)│          │ iCloud/Git sync  │
    │               │          │                  │
    │ → update 词库  │          │ → 导入方案         │
    │ → deploy 方案  │          │ → 加载皮肤/脚本    │
    │ → sync 上游    │          │ → RIME 部署       │
    └───────────────┘          └──────────────────┘
```

## Component Details

### 1. Scheme Core (`scheme/shared/`)
`gins.schema.yaml` 通过 `__include` + `__patch` 继承核心，避免直接修改上游文件。`gins.dict.yaml` 聚合所有词库，`gins.custom.yaml` 添加英文及中英混输翻译器。

### 2. Build Tools (`tools/`)
- **zhwiki-builder** — Rust CLI，从 Wikipedia titles-only `.gz` 文件生成简体中文词库（OpenCC T2S+S2SG + rayon 并行拼音）
- **shici-builder** — Rust CLI，从 chinese-poetry JSON 生成古诗词词库，与核心 shici 去重
- **gins-rime-cli** — Swift CLI，macOS 鼠须管专用：`deploy` / `update` / `sync` / `status`

### 3. Cloudflare Workers (`workers/gins-rime/`)
单一 Worker 同时托管 API 和静态文档站：
- `src/index.ts` — 处理所有 API 路由，其余请求回落到 Workers Assets 静态资产
- `site/` — Astro Starlight 静态文档站（`output: 'static'`，构建产物由 Workers Assets 分发）
- **Bindings**: R2（词库存储）、Queue（构建通知）、Workflow（词库更新管道）

### 4. Platform Configs
- **Squirrel** (`scheme/squirrel/`) — macOS 外观（Gins Purple 主题）、快捷键
- **元书 Hamster v3** (`scheme/hamster/`) — iOS 皮肤（jsonnet）、JS 动作脚本
