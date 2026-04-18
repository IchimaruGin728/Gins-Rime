# 部署、构建与分发

## 最短部署路径

如果你要部署自己的 `Gins-Rime` 分发站，按这个顺序走：

```bash
cd workers/gins-rime
nvm use
pnpm install
pnpm --dir site install
pnpm run deploy:full
```

这会做两件事：

1. 构建 `Astro 6 + Starlight` 文档站
2. 部署 Cloudflare Worker API 与静态资产

## 当前工具链

- `Node.js 25.9.0+`
- `pnpm 10.33+`
- `Wrangler 4.82+`
- `TypeScript 6.0+`
- `Astro 6.1+`
- `Starlight 0.38+`

## Worker 目录

`workers/gins-rime/package.json` 提供的常用命令：

```bash
pnpm run check
pnpm run build
pnpm run site:dev
pnpm run site:preview
pnpm run deploy
pnpm run deploy:full
```

说明：

- `pnpm run check`: 检查 Worker TypeScript
- `pnpm run build`: 构建文档站
- `pnpm run site:dev`: 本地启动 Astro 文档站
- `pnpm run deploy`: 只部署 Worker
- `pnpm run deploy:full`: 先构建文档站，再部署 Worker

## Cloudflare 侧资源

`workers/gins-rime/wrangler.jsonc` 里当前依赖：

- `R2`: 词库与发布产物
- `Workers Assets`: 文档站静态产物
- `Queues`: 构建通知
- `Workflows`: `DictUpdateWorkflow`

部署前至少确认：

1. `r2_buckets` 已指向你的 bucket
2. `queues` 已创建
3. `workflows` 可用
4. 自定义域名或 route 已配置
5. `WORKER_API_TOKEN` 已设置为 Worker secret

设置 secret：

```bash
wrangler secret put WORKER_API_TOKEN
```

## 词库构建链路

### `zhwiki`

触发方式：

- GitHub Actions 定时任务
- 手动触发

流程：

1. 下载 `zhwiki-latest-all-titles-in-ns0.gz`
2. `zhwiki-builder` 过滤与转换标题
3. 生成 `zhwiki.dict.yaml`
4. 上传到 `R2`
5. 触发 `DictUpdateWorkflow`

### `gins-shici`

流程：

1. 拉取 `chinese-poetry`
2. `shici-builder` 去重、转简、生成拼音
3. 上传 `gins-shici.dict.yaml` 到 `R2`

## 客户端更新流

分发链路：

```text
GitHub Actions / Manual Build
  -> R2
  -> Worker /version + /dicts/*
  -> macOS gins-rime 脚本 / Swift CLI
  -> iOS Hamster 导入与同步
```

## 常见操作

### 本地构建文档站

```bash
cd workers/gins-rime
pnpm --dir site build
```

### 本地跑 Worker 类型检查

```bash
cd workers/gins-rime
pnpm run check
```

### 完整部署

```bash
cd workers/gins-rime
pnpm run deploy:full
```

## CI 依赖

Ubuntu 构建 Rust 词库时仍需要 `OpenCC`：

```yaml
- name: Install OpenCC
  run: sudo apt-get install -y libopencc-dev
```
