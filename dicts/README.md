# dicts/

外挂词库目录。所有词库文件均不纳入 git 跟踪，分两类来源：

## 由 CI 自动构建（上传至 R2，`gins-rime update` 下载）

| 文件 | 触发时机 |
|------|---------|
| `zhwiki.dict.yaml` | 每月 2 号（`build-zhwiki.yml`） |
| `gins-shici.dict.yaml` | chinese-poetry 上游更新时（`build-shici.yml`） |

## 由上游同步（`sync-upstream.yml` 自动 PR）

| 文件 | 来源 |
|------|------|
| `tone_moe.dict.yaml` | [suiginko/moetype](https://github.com/suiginko/moetype) 发布时自动下载 |

## 由 Sync 命令同步（`scheme/shared/core/`）

`gins-rime sync` 将 `scheme/shared/core/` 下的上游文件复制到 `~/Library/Rime/`：

| 文件 | 来源 |
|------|------|
| `core/core.schema.yaml` 等 | amzxyz/rime_wanxiang |
| `core/melt_eng.schema.yaml` | iDvel/rime-ice |
| `core/en_dicts/` | iDvel/rime-ice |
