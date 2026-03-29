// Liquid Glass — SVG filter injection + mouse-tracked highlight
// Runs via Astro's Vite pipeline (TypeScript, bundled, deferred)

const FILTER_ID = 'lg-filter'

const FILTER_SVG = `
<defs>
  <filter id="${FILTER_ID}" color-interpolation-filters="sRGB"
    x="-8%" y="-8%" width="116%" height="116%">
    <feTurbulence type="fractalNoise"
      baseFrequency="0.012 0.008"
      numOctaves="3" seed="8" result="noise">
      <animate attributeName="baseFrequency"
        values="0.012 0.008;0.009 0.013;0.015 0.007;0.011 0.010;0.012 0.008"
        dur="14s" repeatCount="indefinite"
        calcMode="spline"
        keySplines="0.4 0 0.6 1;0.4 0 0.6 1;0.4 0 0.6 1;0.4 0 0.6 1"/>
    </feTurbulence>
    <feGaussianBlur in="noise" stdDeviation="0.6" result="smooth"/>
    <feDisplacementMap in="SourceGraphic" in2="smooth"
      scale="22" xChannelSelector="R" yChannelSelector="G"/>
  </filter>
</defs>`.trim()

function injectFilter(): void {
  if (document.getElementById(FILTER_ID)) return

  const svg = document.createElementNS('http://www.w3.org/2000/svg', 'svg')
  svg.setAttribute('aria-hidden', 'true')
  svg.style.cssText = 'position:fixed;width:0;height:0;overflow:hidden;pointer-events:none'
  svg.innerHTML = FILTER_SVG
  document.body.prepend(svg)
}

function initHighlightTracking(): void {
  let raf: number
  const root = document.documentElement

  document.addEventListener('pointermove', (e: PointerEvent) => {
    cancelAnimationFrame(raf)
    raf = requestAnimationFrame(() => {
      root.style.setProperty('--hl-x', `${(e.clientX / innerWidth  * 100).toFixed(1)}%`)
      root.style.setProperty('--hl-y', `${(e.clientY / innerHeight * 100).toFixed(1)}%`)
    })
  }, { passive: true })
}

// Initial run
injectFilter()
initHighlightTracking()

// Re-inject after Astro page transitions
document.addEventListener('astro:page-load', injectFilter)
