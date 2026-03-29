import { defineConfig } from 'astro/config'
import starlight from '@astrojs/starlight'
import preact from '@astrojs/preact'
import UnoCSS from '@unocss/astro'

export default defineConfig({
  output: 'static',
  integrations: [
    starlight({
      title: 'Gins-Rime',
      description: '万象拼音 + 萌娘百科 + 雾凇中英混输，macOS / iOS 双平台',
      social: [
        { icon: 'github', label: 'GitHub', href: 'https://github.com/IchimaruGin728/Gins-Rime' },
      ],
      customCss: ['./src/styles/gins.scss', './src/styles/glass.scss'],
      sidebar: [
        {
          label: '快速开始',
          link: '/',
        },
        {
          label: '方案',
          items: [
            { label: '方案设计', slug: 'scheme' },
            { label: '词库系统', slug: 'dicts' },
          ],
        },
        {
          label: '平台',
          items: [
            { label: '鼠须管 macOS', slug: 'squirrel' },
            { label: '元书 iOS', slug: 'hamster' },
          ],
        },
        {
          label: '开发',
          items: [
            { label: 'CI 构建', slug: 'build' },
            { label: '上游同步', slug: 'upstream' },
          ],
        },
      ],
      components: {
        Head: './src/components/Head.astro',
        Header: './src/components/SiteHeader.astro',
      },
    }),
    preact({ compat: true }),
    UnoCSS({ injectReset: false }),
  ],
})
