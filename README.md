# Gins-Rime

个人 RIME 输入法配置，macOS 鼠须管 + iOS 元书 Hamster v3。

基于万象拼音构建，合并萌娘百科、雾凇中英混输，以及自建维基百科标题词库。词库通过 GitHub Actions 构建，由 Cloudflare Worker 分发。

## 文档

- [方案设计](docs/scheme.md)
- [词库系统](docs/dicts.md)
- [鼠须管配置](docs/squirrel.md)
- [元书配置](docs/hamster.md)
- [CI 构建与分发](docs/build.md)
- [上游同步](docs/upstream.md)

---

## 致谢

- [amzxyz/rime_wanxiang](https://github.com/amzxyz/rime_wanxiang) — 基础拼音方案、核心词库、Lua 脚本
- [iDvel/rime-ice](https://github.com/iDvel/rime-ice) — melt_eng 中英混输、英文词库
- [suiginko/moetype](https://github.com/suiginko/moetype) — 萌娘百科 ACG 词库
- [chinese-poetry/chinese-poetry](https://github.com/chinese-poetry/chinese-poetry) — 古诗词数据源
- [Wikimedia](https://dumps.wikimedia.org/zhwiki/) — 中文维基百科标题
