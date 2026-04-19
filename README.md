# Gins-Rime

> **个人定制分发版**
>
> 本项目遵循 **GPL v3** 开源协议。

个人 Rime 输入法配置，面向 `macOS Squirrel` 和 `iOS Hamster`，带有自定义方案、外挂词库、Cloudflare 分发层和文档站。

## 现在的技术栈

- `Node.js 25.9.0+` + `.nvmrc`
- `pnpm 10.33+` for `workers/gins-rime`
- `pnpm 10.33+` for `workers/gins-rime/site`
- `Wrangler 4.82+`
- `Astro 6.1+` + `Starlight 0.38+`
- `TypeScript 5.9+`
- `Cloudflare Workers / R2 / Workflows / Queues`
- `Swift Package Manager` for `gins-rime-cli`
- `Rust` for `zhwiki-builder` and `shici-builder`

## 你可以怎么用

### 1. 只想安装现成方案

macOS:

```bash
git clone https://github.com/IchimaruGin728/Gins-Rime.git
cd Gins-Rime
./tools/gins-rime deploy
./tools/gins-rime update
```

常用命令:

```bash
./tools/gins-rime status
./tools/gins-rime sync --dry-run
```

### 2. 想看文档站

```bash
cd workers/gins-rime
nvm use
pnpm --dir site install
pnpm install
pnpm run site:dev
```

### 3. 想自己部署 Cloudflare 分发层

```bash
cd workers/gins-rime
nvm use
pnpm install
pnpm --dir site install
pnpm run check
pnpm run deploy:full
```

## 仓库结构

- `scheme/shared/`: 共享 schema、词典聚合、patch
- `scheme/squirrel/`: macOS 鼠须管配置
- `scheme/hamster/`: iOS 元书配置、脚本、皮肤
- `lua/core/`: Lua translator / filter / processor 扩展
- `tools/gins-rime`: 本地部署与更新脚本
- `tools/gins-rime-cli/`: Swift CLI
- `tools/zhwiki-builder/`: 维基标题词库构建器
- `tools/shici-builder/`: 古诗词词库构建器
- `workers/gins-rime/`: Cloudflare Worker API + 文档站分发

## 用户部署路径

### macOS 本地部署

1. 安装 `Squirrel`
2. 克隆仓库
3. 运行 `./tools/gins-rime deploy`
4. 运行 `./tools/gins-rime update`
5. 在鼠须管里重新部署

### iOS/Hamster 导入

1. 从仓库导入 `scheme/shared` 和 `scheme/hamster`
2. 确认皮肤、脚本与 custom patch 一起导入
3. 在 Hamster 中执行重新部署

### Cloudflare 自托管

1. 准备 `R2`、`Queue`、`Workflow`
2. 配置 `workers/gins-rime/wrangler.jsonc`
3. 安装 worker 与 site 依赖
4. 执行 `pnpm run check`
5. 执行 `pnpm run deploy:full`

如果你希望本地脚本或 Swift CLI 指向你自己的 Worker，而不是默认的官方域名：

```bash
export GINS_RIME_WORKER="https://your-rime.example.com"
```

更详细的流程见：

- [方案设计](docs/scheme.md)
- [词库系统](docs/dicts.md)
- [CI 构建与分发](docs/build.md)
- [鼠须管配置](docs/squirrel.md)
- [元书配置](docs/hamster.md)
- [上游同步](docs/upstream.md)
- [架构说明](ARCHITECTURE.md)

## 致谢

本方案基于以下上游项目与数据源：

1. **[amzxyz/rime_wanxiang](https://github.com/amzxyz/rime_wanxiang)**
2. **[iDvel/rime-ice](https://github.com/iDvel/rime-ice)**
3. **[suiginko/moetype](https://github.com/suiginko/moetype)**
4. **[chinese-poetry](https://github.com/chinese-poetry/chinese-poetry)**
5. **[Wikimedia](https://dumps.wikimedia.org/zhwiki/)**

## 协议

Copyright (c) 2026 IchimaruGin728. 基于 **GPL v3** 协议授权。核心上游文件遵循其原作者之授权协议。
