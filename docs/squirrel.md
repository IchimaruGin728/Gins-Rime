# 鼠须管配置（macOS）

## 主题：Gins Purple

横排候选，深紫背景，亮紫高亮。颜色格式为 Squirrel 的 `0xAARRGGBB`（注意不是 `#RRGGBBAA`）。

| 元素 | 颜色 | Hex |
|------|------|-----|
| 背景 | 深靛蓝 | `#1E1B4B` |
| 边框 | 中紫 | `#3D3580` |
| 高亮背景 | 亮紫（Tailwind violet-600） | `#7C3AED` |
| 候选文字 | 浅紫白 | `#D8D0FF` |
| 拼音注释 | 灰紫 | `#7B6FA8` |

## 关键配置说明

**`candidate_list_layout: linear`** — 横排候选词。万象默认 `page_size: 6`，7890 键位用于声调辅助筛选（按声调过滤候选），改成 9 会影响这个功能。

**`translucency: false`** — 关闭毛玻璃效果。开启时桌面底色会透过背景影响颜色观感，深色桌面下紫色会偏蓝或偏粉。

**`inline_preedit: true`** — 输入码显示在文档光标处，不在悬浮窗里重复显示。

## 快捷键

| 快捷键 | 功能 |
|--------|------|
| `Ctrl+Shift+4` | 简繁切换 |
| `Ctrl+Shift+E` | 中英混输开关 |
| `Caps Lock` | 清空输入（不切换大写） |
| `Shift_L / Shift_R` | 无操作（避免误触切换英文） |
