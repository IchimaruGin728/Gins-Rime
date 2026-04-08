# Gins-Rime

> **个人定制分发版 (Personal Distribution)**
> 
> 本项目遵循 **GPL v3** 开源协议。

个人 RIME 输入法配置，专为 macOS 鼠须管 (Squirrel) 与 iOS 元书 (Hamster) 打造。

## 特色
- **多端分发**：基于 Cloudflare Worker 实现词库与配置方案的海量全量云端同步。
- **极致体验**：苹果官方风格 UI 深度定制。
- **混合动力**：万象拼音内核 + 雾凇词库 + 自建维基/古诗词词库。

## 文档
- [方案设计](docs/scheme.md) | [词库系统](docs/dicts.md) | [分发系统](docs/build.md)

---

## 致谢 (Credits & Upstreams)

本方案“因巨人而强大”，核心组件源自以下优秀开源项目：

1. **[amzxyz/rime_wanxiang](https://github.com/amzxyz/rime_wanxiang)** 
   — 方案内核、Lua 脚本、基础词库（即本项目中的 `core` 部分）。
2. **[iDvel/rime-ice](https://github.com/iDvel/rime-ice)** 
   — melt_eng 混输逻辑、高质量英文词库（雾凇拼音）。
3. **[suiginko/moetype](https://github.com/suiginko/moetype)** 
   — 核心 ACG 扩展词库。
4. **[chinese-poetry](https://github.com/chinese-poetry/chinese-poetry)** 
   — 古诗词基础数据。
5. **[Wikimedia](https://dumps.wikimedia.org/zhwiki/)** 
   — 维基百科标题数据。

---

## 协议 (License)

Copyright (c) 2026 IchimaruGin728. 基于 **GPL v3** 协议授权。核心上游文件遵循其原作者之授权协议。
