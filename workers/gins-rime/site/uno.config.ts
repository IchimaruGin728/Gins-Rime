import { defineConfig, presetUno, presetAttributify } from 'unocss'

export default defineConfig({
  presets: [
    presetUno(),
    presetAttributify(),
  ],

  theme: {
    colors: {
      brand: {
        primary: '#581C87',
        accent:  '#C084FC',
      },
    },
    fontFamily: {
      sans:    ['Inter Variable', 'system-ui', 'sans-serif'],
      mono:    ['JetBrains Mono Variable', 'monospace'],
      display: ['Outfit Variable', 'Inter Variable', 'sans-serif'],
    },
  },

  shortcuts: {
    // 和 Blog 完全一样的 glass-panel
    'glass-panel': 'bg-white/10 backdrop-blur-xl border border-white/10 shadow-xl',
    'glass-dark':  'bg-black/20 backdrop-blur-xl border border-white/8 shadow-xl',
  },
})
