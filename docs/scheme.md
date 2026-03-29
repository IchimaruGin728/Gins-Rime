# 方案设计

Gins-Rime 不是从零写一套 RIME 方案，而是在万象拼音的基础上做最小化叠加。

## 为什么选万象

万象拼音内置了 24 个 Lua 脚本，覆盖了大部分进阶需求：

- `V` 前缀计算器
- `/rq` 或 `orq` 日期时间（含农历、节气）
- `U` 前缀 Unicode 输入
- `R` 前缀大写数字
- 简繁转换（`Ctrl+Shift+4`）
- 自训练预测
- 声调辅助筛选（候选词按声调过滤）

这些不需要额外 patch，万象 schema 已内置，直接继承就能用。

## 继承方式

`gins.schema.yaml` 用 `__include` 完整继承万象配置，只覆盖三项：

```yaml
__include: wanxiang.schema:/

__patch:
  schema/schema_id: gins
  schema/name: Gins拼音
  translator/dictionary: gins    # 主词库指向 gins.dict.yaml
```

输入法选择器里显示为 **Gins拼音**，用户词典文件为 `gins.userdb`。

## 文件职责

| 文件 | 职责 |
|------|------|
| `gins.schema.yaml` | 继承万象，覆盖方案标识和主词库 |
| `gins.dict.yaml` | 聚合所有词库的索引文件 |
| `gins.custom.yaml` | 追加 melt_eng 中英混输、快捷键绑定 |
| `melt_eng.dict.yaml` | 雾凇英文词库索引（en + en_ext） |

## 词库编码格式

万象使用 Unicode 带调拼音（`ā á ǎ à`），所有外挂词库必须使用相同格式，否则无法被声调辅助筛选识别。自建词库（zhwiki、gins-shici）均通过 Rust 的 `pinyin` crate 生成带调拼音。
