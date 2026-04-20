import { defineConfig, presetAttributify, presetWind4 } from 'unocss'

export default defineConfig({
  presets: [
    presetWind4(),
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
    'section-label': 'text-xs font-semibold uppercase tracking-[0.16em] text-[var(--sl-color-text-accent)]/70',
    'surface-card': 'rounded-2xl border border-[var(--sl-color-hairline)] bg-[var(--sl-color-gray-7)]/20 p-4',
    'surface-card-hover': 'block rounded-2xl border border-[var(--sl-color-hairline)] bg-[var(--sl-color-gray-7)]/20 p-4 no-underline transition duration-150 ease-out hover:-translate-y-0.5 hover:border-[var(--sl-color-text-accent)]/30 hover:bg-[var(--sl-color-gray-6)]/30',
    'surface-title': 'block text-sm font-semibold text-[var(--sl-color-white)]',
    'surface-sub': 'mt-1 block text-xs text-[var(--sl-color-gray-3)]',
    'surface-meta': 'font-mono text-sm text-[var(--sl-color-text-accent)]',
    'surface-meta-muted': 'text-xs text-[var(--sl-color-gray-3)]',
    'primary-btn': 'inline-flex w-fit items-center justify-center rounded-full bg-violet-600 px-5 py-2.5 text-sm font-semibold text-white no-underline shadow-lg shadow-violet-900/25 transition duration-150 hover:bg-violet-500',
  },
})
