# 词库系统

## 万象核心词库

万象的词库文件在 `~/Library/Rime/dicts/`，通过 `dicts/` 前缀引用。

| 词库 | 条目数 | 内容 |
|------|--------|------|
| `dicts/zi` | ~51k | 字表，所有汉字及拼音 |
| `dicts/jichu` | ~1474k | 核心词汇，2-3 字词为主 |
| `dicts/lianxiang` | ~366k | 联想词汇，5 字以上长词组 |
| `dicts/cuoyin` | ~156 | 常见错音纠正 |
| `dicts/duoyin` | ~5.4k | 多音字兼容处理 |
| `dicts/shici` | ~328k | 古诗词，唐宋元明清全覆盖 |
| `dicts/diming` | ~71k | 地名，省市县级 |
| `dicts/renming` | ~65k | 人名，历史及现代 |
| `dicts/wuzhong` | ~72k | 物种名称 |

## 外挂词库

外挂词库通过 CI 构建并上传到 Cloudflare R2，部署时由 `gins-rime deploy` 下载到本地。

### tone_moe（萌娘百科）

来源：[moetype/Moegirl-RIME](https://github.com/moetype/Moegirl-RIME)

ACG 圈子词汇，涵盖动漫、游戏、VTuber、二次元梗等万象完全没有的领域。使用带调拼音编码，与万象格式兼容。

### zhwiki（维基百科标题）

来源：Wikimedia dump `zhwiki-latest-all-titles-in-ns0.gz`

从中文维基百科的文章标题提取词条，经过 OpenCC T2S → S2SG 转换，保留 CN/SG 简体词汇。titles 文件仅几十 MB，CI 构建 < 5 分钟。

过滤规则：
- 只取 ns=0（正文命名空间，排除 Template/Category 等）
- 排除含 `/`、`(` 的标题（子页面、消歧义页）
- 长度 2–20 字

### gins-shici（古诗词补充）

来源：[chinese-poetry/chinese-poetry](https://github.com/chinese-poetry/chinese-poetry)

唐诗、宋词、元曲的诗句和词牌名。**与万象 shici 去重后合并**，只收录万象没有的条目。经 T2S 转换确保简体输出。

## 中英混输

雾凇提供两套中英词库，挂载方式不同：

**`dicts/cn&en`**（万象内置，1868 条）— 带调拼音格式，直接进 `import_tables`。收录 U盘、B站、WiFi 等高频中英混合词。

**`en_dicts/cn_en.txt`**（雾凇，~1000 条）— tabledb 格式，编码是英文拼写拼接（如 `txu`、`xguang`），不兼容带调拼音，作为独立 `table_translator@cn_en` 挂载，`initial_quality: 0.5`。

**`melt_eng`**（雾凇，~25k 条）— 纯英文词库（`en` + `en_ext`），英文字符为编码，作为 `table_translator@melt_eng` 挂载，`initial_quality: 1.1`，优先级低于中文候选、高于 cn_en。
