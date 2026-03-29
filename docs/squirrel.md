## 主题：Gins Liquid

模仿 macOS 26 Liquid Glass 原生输入法质感：`translucency: true` 启用 macOS vibrancy 磨砂效果，浅色深色各一套 scheme 随系统自动切换。颜色格式为 Squirrel 的 `0xAARRGGBB`（AA 为 alpha，可半透明）。

### 浅色（Gins Liquid Light）

| 元素 | 颜色 |
|------|------|
| 背景 | `0xD9FFFFFF` 磨砂白，85% 不透明 |
| 高亮背景 | `0xFF007AFF` 系统蓝 |
| 候选文字 | `0xFF3C3C43` iOS primary label |
| 拼音注释 | `0xFF8E8E93` iOS secondary label |

### 深色（Gins Liquid Dark）

| 元素 | 颜色 |
|------|------|
| 背景 | `0xD91C1C1E` 磨砂黑，85% 不透明 |
| 高亮背景 | `0xFF0A84FF` 系统蓝（深色模式） |
| 候选文字 | `0xFFEBEBF5` iOS primary label dark |
| 拼音注释 | `0xFF8E8E93` iOS secondary label |

## 关键配置说明

**`translucency: true`** — 启用 macOS vibrancy 磨砂背景，候选框跟随桌面内容变色。

**`candidate_list_layout: linear`** — 横排候选词。万象默认 `page_size: 6`，7890 键位用于声调辅助筛选（按声调过滤候选），改成 9 会影响这个功能。

**`inline_preedit: true`** — 输入码显示在文档光标处，不在悬浮窗里重复显示。

## 快捷键

| 快捷键 | 功能 |
|--------|------|
| `Ctrl+Shift+4` | 简繁切换 |
| `Caps Lock` | 清空输入缓冲（不切换大写） |

中英混输由 `melt_eng` 自动处理，无需手动切换模式。`Shift` 键设为无操作，避免误触切换英文。
