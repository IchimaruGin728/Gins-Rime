## 主题：Squirrel Official

鼠须管候选条现在按官方输入法的视觉比例收敛：浅灰磨砂底板、紫色高亮胶囊、恢复数字标签、横排紧凑间距。`translucency: true` 会启用 macOS vibrancy 磨砂效果，浅色深色各一套 scheme 随系统自动切换。颜色格式为 Squirrel 的 `0xAARRGGBB`。

### 浅色（Squirrel Official Light）

| 元素 | 颜色 |
|------|------|
| 背景 | `0xEAF2F2F7` 官方浅灰磨砂 |
| 高亮背景 | `0xE0B915D8` 半透明系统紫 |
| 候选文字 | `0xFF1F1F1F` 深色正文 |
| 数字标签 | `0x99575757` 次级灰 |

### 深色（Squirrel Official Dark）

| 元素 | 颜色 |
|------|------|
| 背景 | `0xCC2C2C2E` 官方深色磨砂 |
| 高亮背景 | `0xE0B915D8` 半透明系统紫 |
| 候选文字 | `0xFFF2F2F7` 浅色正文 |
| 数字标签 | `0x99D0D0D0` 次级灰 |

## 关键配置说明

**`translucency: true`** — 启用 macOS vibrancy 磨砂背景，候选框跟随桌面内容变色。

**`candidate_list_layout: linear`** — 横排候选词，保留官方那种一整条候选栏的阅读方向。核心默认 `page_size: 6`，7890 键位用于声调辅助筛选。

**`inline_preedit: true`** — 输入码显示在文档光标处，不在悬浮窗里重复显示。

**`label_font_point: 11`** — 恢复官方样式里每个候选项前面的数字标签，而不是隐藏掉。

## 快捷键

| 快捷键 | 功能 |
|--------|------|
| `Ctrl+Shift+4` | 简繁切换 |
| `Caps Lock` | 清空输入缓冲（不切换大写） |

中英混输由 `melt_eng` 自动处理，无需手动切换模式。`Shift` 键设为无操作，避免误触切换英文。
