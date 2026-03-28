# Gins-Rime Architecture

## Overview

Gins-Rime 是基于万象拼音（wanxiang）的个人定制 RIME 输入方案，覆盖 macOS（鼠须管 Squirrel）和 iOS（元书输入法 Hamster v3）双平台。

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          Gins-Rime  Architecture                            │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   ┌─────────────────────── Upstream Sources ───────────────────────┐        │
│   │                                                                 │        │
│   │  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────┐  │        │
│   │  │  万象拼音      │  │  雾凇拼音      │  │  萌娘百科词库        │  │        │
│   │  │  (wanxiang)   │  │  (rime-ice)  │  │  (moetype)          │  │        │
│   │  │              │  │              │  │                      │  │        │
│   │  │ • base scheme │  │ • melt_eng   │  │ • moegirl.dict.yaml │  │        │
│   │  │ • jichu.dict  │  │   混输翻译器    │  │ • ACG 专有名词       │  │        │
│   │  │ • 200M 语法模型 │  │ • en dicts   │  │                      │  │        │
│   │  │ • renming     │  │ • Lua 脚本    │  │                      │  │        │
│   │  │ • wuzhong     │  │              │  │                      │  │        │
│   │  │ • Lua 扩展     │  │              │  │                      │  │        │
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
│   │         │     │  XML dump → 流式解析    │          │              │        │
│   │         │     │  → rust-pinyin 标注    │          │              │        │
│   │         │     │  → OpenCC s2sg 过滤    │          │              │        │
│   │         │     │  → zhwiki.dict.yaml   │          │              │        │
│   │         │     └───────────┬───────────┘          │              │        │
│   │         │                 │                      │              │        │
│   │         ▼                 ▼                      ▼              │        │
│   │  ┌─────────────────────────────────────────────────────┐       │        │
│   │  │              wanxiang.dict.yaml                      │       │        │
│   │  │                                                      │       │        │
│   │  │  import_tables:                                      │       │        │
│   │  │    - jichu        (万象核心词库)                        │       │        │
│   │  │    - renming      (人名词库)                           │       │        │
│   │  │    - wuzhong      (物种词库)                           │       │        │
│   │  │    - zhwiki       (维基百科词库 · Rust build)           │       │        │
│   │  │    - moegirl      (萌娘百科词库)                        │       │        │
│   │  │    - rime_ice.en  (雾凇英文词库)                        │       │        │
│   │  └─────────────────────────────────────────────────────┘       │        │
│   │                           │                                     │        │
│   │                           ▼                                     │        │
│   │  ┌─────────────────────────────────────────────────────┐       │        │
│   │  │          wanxiang.custom.yaml (patch)                │       │        │
│   │  │                                                      │       │        │
│   │  │  patch:                                              │       │        │
│   │  │    engine/translators/+:                             │       │        │
│   │  │      - table_translator@melt_eng  (雾凇混输)          │       │        │
│   │  │    melt_eng:                                         │       │        │
│   │  │      dictionary: melt_eng                            │       │        │
│   │  │      enable_sentence: false                          │       │        │
│   │  │    key_binder/bindings/+: ...                        │       │        │
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
│   │  │  │   .yaml          │    │  │   └── *.lua           │    │           │
│   │  │  └── (外观/快捷键)    │    │  └── skins/             │    │           │
│   │  │                     │    │      └── *.jsonnet        │    │           │
│   │  │  gins-rime-cli      │    │                          │    │           │
│   │  │  (Swift CLI)        │    │  iCloud / Git 同步        │    │           │
│   │  │  ├── deploy         │    │                          │    │           │
│   │  │  ├── update         │    │                          │    │           │
│   │  │  ├── sync           │    │                          │    │           │
│   │  │  └── customize      │    │                          │    │           │
│   │  └─────────────────────┘    └──────────────────────────┘    │           │
│   │                                                              │           │
│   └──────────────────────────────────────────────────────────────┘           │
│                                                                             │
│   ┌───────────────── Infrastructure (GitHub + Cloudflare) ──────────┐       │
│   │                                                                  │       │
│   │  GitHub Actions                    Cloudflare                    │       │
│   │  ┌─────────────────────┐          ┌─────────────────────────┐   │       │
│   │  │ build-zhwiki.yml    │          │  Workers (API)           │   │       │
│   │  │  cron: weekly       │          │  • /api/version          │   │       │
│   │  │  → Rust build       │          │  • /api/dicts/{name}     │   │       │
│   │  │  → artifact upload  │          │  • /api/scheme/latest    │   │       │
│   │  │                     │          │                          │   │       │
│   │  │ release.yml         │          │  Workflows               │   │       │
│   │  │  → scheme packaging │          │  • dict build pipeline   │   │       │
│   │  │  → CF Workers deploy│          │  • diff & notify         │   │       │
│   │  │                     │          │                          │   │       │
│   │  │ sync-upstream.yml   │          │  Queues                  │   │       │
│   │  │  → pull upstream    │          │  • update-notifications  │   │       │
│   │  │  → diff & PR        │          │  • build-triggers        │   │       │
│   │  └─────────────────────┘          │                          │   │       │
│   │                                    │  R2 (Storage)            │   │       │
│   │                                    │  • dict artifacts        │   │       │
│   │                                    │  • release packages      │   │       │
│   │                                    └─────────────────────────┘   │       │
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
    │ zhwiki dump      │ │ moetype   │  │ rime-ice     │
    │ (Rust builder)   │ │ (git pull)│  │ (git pull)   │
    └────────┬────────┘ └─────┬─────┘  └──────┬───────┘
             │                │               │
             ▼                ▼               ▼
    ┌─────────────────────────────────────────────────┐
    │          GitHub Release / R2 Storage              │
    │     (zhwiki.dict.yaml, moegirl.dict.yaml, ...)   │
    └────────────────────┬────────────────────────────┘
                         │
          ┌──────────────┼──────────────┐
          ▼                             ▼
    ┌───────────────┐          ┌──────────────────┐
    │ gins-rime-cli │          │ 元书 Hamster v3  │
    │ (Swift · macOS)│          │ iCloud/Git sync  │
    │               │          │                  │
    │ → 下载词库      │          │ → 导入方案         │
    │ → patch 方案    │          │ → 加载皮肤/脚本    │
    │ → 部署鼠须管     │          │ → RIME 部署       │
    └───────────────┘          └──────────────────┘
```

## Component Details

### 1. Scheme Core (`scheme/shared/`)
万象拼音基础方案 + 自定义 patch，双平台共享。

### 2. zhwiki-builder (`tools/zhwiki-builder/`)
Rust CLI，从维基百科 dump 生成简体中文词库。
- `quick-xml` 流式解析 XML
- `rust-pinyin` 标注声调拼音
- OpenCC `s2sg.json` 过滤 CN/SG 简体
- 输出万象格式 dict.yaml

### 3. gins-rime-cli (`tools/gins-rime-cli/`)
Swift CLI，macOS 鼠须管专用管理工具。
- `deploy` — 一键部署方案到 `~/Library/Rime`
- `update` — 拉取最新词库/方案更新
- `sync` — 同步用户词典 & 配置
- `customize` — 交互式自定义（主题、词库开关等）

### 4. Cloudflare Workers (`workers/api/`)
- **Workers**: API 服务（版本查询、词库下载、方案分发）
- **Workflows**: 词库构建管道、差异检测与通知
- **Queues**: 构建触发、更新推送
- **R2**: 词库产物 & release 包存储

### 5. Platform Configs
- **Squirrel** (`scheme/squirrel/`): macOS 外观、快捷键
- **元书 Hamster v3** (`scheme/hamster/`): iOS 皮肤 (jsonnet)、脚本 (JS)

## Suggested Additional Schemes

| 方案 | 用途 | 来源 |
|------|------|------|
| 符号输入 | Emoji + 特殊符号快捷输入 | 万象/雾凇内置 |
| 日期时间 | `/date` `/time` 快捷输入 | Lua 脚本 |
| 计算器 | `/calc 1+1` 行内计算 | Lua 脚本 |
| Unicode | `/uni` 码点查询输入 | Lua 脚本 |
| 粤语混输 | 粤拼辅助输入（可选） | rime-cantonese |
| 日语混输 | 平假名/片假名快捷输入（可选） | 自定义 table |
