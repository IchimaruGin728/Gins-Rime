// Gins-Rime: 元书 Hamster v3 暗色皮肤
// Jsonnet 格式，元书输入法 v3 皮肤系统

local colors = {
  bg: '#1E1E2E',
  surface: '#2D2D3D',
  primary: '#4A90D9',
  text: '#E8E8E8',
  textSecondary: '#888888',
  border: '#3D3D4D',
  highlight: '#5A5A6A',
};

{
  name: 'Gins Dark',
  author: 'Gins-Rime',
  version: '0.1',

  keyboard: {
    backgroundColor: colors.bg,
    keyBackgroundColor: colors.surface,
    keyPressedBackgroundColor: colors.highlight,
    keyTextColor: colors.text,
    keyBorderColor: colors.border,
    keyBorderWidth: 0.5,
    keyCornerRadius: 6,
    keyHeight: 42,
    keySpacing: 4,
    rowSpacing: 8,
    insets: { top: 4, bottom: 4, left: 4, right: 4 },
  },

  candidateBar: {
    backgroundColor: colors.surface,
    textColor: colors.text,
    highlightedTextColor: '#FFFFFF',
    highlightedBackgroundColor: colors.primary,
    commentTextColor: colors.textSecondary,
    labelTextColor: colors.textSecondary,
    fontSize: 16,
    height: 44,
  },

  inputArea: {
    backgroundColor: colors.bg,
    textColor: colors.text,
    cursorColor: colors.primary,
  },
}
