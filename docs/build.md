# CI 构建与分发

## 架构

```
GitHub Actions (构建词库) → Cloudflare R2 (存储) → Worker API (分发) → 客户端
```

## 词库构建流程

### zhwiki

触发：每周一次（cron），或手动触发

1. 下载 `zhwiki-latest-all-titles-in-ns0.gz`（~100MB）
2. Rust `zhwiki-builder` 处理：过滤 ns=0 标题 → OpenCC T2S+S2SG 转换 → 生成带调拼音
3. 验证条目数 > 100k
4. 上传 `zhwiki.dict.yaml` 到 R2
5. 触发 Worker 的 `DictUpdateWorkflow`

构建耗时约 5 分钟（瓶颈是 gzip 解压，非计算）。

### gins-shici

触发：手动，或 chinese-poetry 仓库更新时

1. Clone `chinese-poetry/chinese-poetry`
2. Rust `shici-builder` 处理：解析 JSON → T2S 转换 → 与万象 shici 去重 → 生成带调拼音
3. 上传 `gins-shici.dict.yaml` 到 R2

构建耗时 < 2 分钟。

## Worker API

部署在 `gins-rime-api.ichimarugin728.workers.dev`。

| 路由 | 说明 |
|------|------|
| `GET /version` | 最新版本信息 |
| `GET /dicts/:name` | 下载词库文件 |
| `GET /releases/:version/:file` | 下载发布产物 |
| `POST /workflow/dict-update` | 触发 DictUpdateWorkflow |
| `GET /workflow/:id` | 查询 Workflow 状态 |

## DictUpdateWorkflow

Cloudflare Workflow，在词库更新后：

1. 验证 R2 中的文件是否存在且有效
2. 更新 `latest.json` 版本清单
3. 向队列推送更新通知

Workflow 使用 durable execution，步骤失败自动重试，不会因 Worker 超时中断。

## CI 依赖

构建环境需要 `libopencc-dev`（Ubuntu）：

```yaml
- name: Install OpenCC
  run: sudo apt-get install -y libopencc-dev
```
