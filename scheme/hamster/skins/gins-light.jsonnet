// Gins-Rime: 元书 Hamster v3 亮色皮肤

local colors = {
  bg: '#F5F5F5',
  surface: '#FFFFFF',
  primary: '#4A90D9',
  text: '#333333',
  textSecondary: '#999999',
  border: '#E0E0E0',
  highlight: '#E8E8E8',
};

{
  name: 'Gins Light',
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
    backgroundColor: colors.surface,
    textColor: colors.text,
    cursorColor: colors.primary,
  },
}
