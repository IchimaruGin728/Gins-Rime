## 策略

上游更新通过 GitHub Actions 定时检测，有变化时自动开 PR，人工确认后合并。不自动合并，避免上游破坏性更新直接进主分支。

检测频率：
- 万象、萌娘百科、雾凇、古诗词：每天 **07:28** 和 **17:16**（CST）各检测一次
- zhwiki：每月 **2 号 02:00 UTC** 跑一次（Wikimedia dump 1 号 UTC 开始生成，titles 文件数小时内就绪）

## 同步来源

### 万象拼音（amzxyz/rime_wanxiang）

检测方式：GitHub Releases latest tag

同步内容：
- `wanxiang.schema.yaml` — 主方案文件，我们的 `gins.schema.yaml` 通过 `__include` 继承它
- `wanxiang_algebra.yaml` — 拼音变换规则
- `wanxiang_symbols.yaml` — 符号定义

词库（`dicts/`）通过 `gins-rime deploy` 从鼠须管安装目录直接取，不进仓库。

### 雾凇拼音（iDvel/rime-ice）

检测方式：`melt_eng.schema.yaml` 最新 commit sha

同步内容：
- `melt_eng.schema.yaml`
- `en_dicts/en.dict.yaml` + `en_dicts/en_ext.dict.yaml`
- `en_dicts/cn_en.txt`

### 萌娘百科（suiginko/moetype）

检测方式：GitHub Releases latest tag

同步内容：
- `tone_moe.dict.yaml` — 直接写入 `dicts/`，同时上传 R2

## 存放位置

同步到仓库的上游文件放在 `scheme/shared/upstream/`，不直接覆盖我们的配置，由 CLI 的 `gins-rime sync` 命令负责将 upstream/ 内容复制到 `~/Library/Rime/`。

版本记录在 `.upstream/` 目录：

```
.upstream/
  wanxiang.tag        # 万象最新 tag
  moetype.tag         # moetype 最新 tag
  rime-ice-melt.sha   # rime-ice melt_eng 最新 commit sha
```

## 手动触发

```bash
# GitHub Actions 页面手动触发
gh workflow run sync-upstream.yml

# 或本地
gins-rime sync
```
