// Liquid Glass — SVG filter injection + mouse-tracked highlight
// Runs via Astro's Vite pipeline (TypeScript, bundled, deferred as type="module")

const FILTER_ID = 'lg-filter'

// ── Browser capability detection ─────────────────────────────────────────────
// SVG backdrop-filter (url()) only works in Chromium. Safari + Firefox fall
// through to the plain blur() path defined in glass.scss without @supports.
const SUPPORTS_SVG_BACKDROP = CSS.supports('backdrop-filter', "url('#x')")
const REDUCED_MOTION = matchMedia('(prefers-reduced-motion: reduce)').matches

// ── SVG filter template ───────────────────────────────────────────────────────
// feTurbulence animates only in Chromium (where it's compositor-accelerated).
// In reduced-motion mode we omit the <animate> entirely — static displacement.
function buildFilterSVG(): string {
  const animate = (!REDUCED_MOTION && SUPPORTS_SVG_BACKDROP)
    ? `<animate attributeName="baseFrequency"
        values="0.012 0.008;0.009 0.013;0.015 0.007;0.011 0.010;0.012 0.008"
        dur="14s" repeatCount="indefinite"
        calcMode="spline"
        keySplines="0.4 0 0.6 1;0.4 0 0.6 1;0.4 0 0.6 1;0.4 0 0.6 1"/>`
    : ''

  return `<defs>
  <filter id="${FILTER_ID}" color-interpolation-filters="sRGB"
    x="-8%" y="-8%" width="116%" height="116%">
    <feTurbulence type="fractalNoise"
      baseFrequency="0.012 0.008"
      numOctaves="3" seed="8" result="noise">
      ${animate}
    </feTurbulence>
    <feGaussianBlur in="noise" stdDeviation="0.6" result="smooth"/>
    <feDisplacementMap in="SourceGraphic" in2="smooth"
      scale="22" xChannelSelector="R" yChannelSelector="G"/>
  </filter>
</defs>`
}

// ── SVG filter injection ──────────────────────────────────────────────────────
// Injected into <body> (not <head>) — SVG filters must be in the render tree.
// Guard prevents duplicate injection on Astro SPA page transitions.
function injectFilter(): void {
  if (!SUPPORTS_SVG_BACKDROP) return   // Safari/Firefox use pure blur — no SVG needed
  if (document.getElementById(FILTER_ID)) return

  const svg = document.createElementNS('http://www.w3.org/2000/svg', 'svg')
  svg.setAttribute('aria-hidden', 'true')
  svg.style.cssText = 'position:fixed;width:0;height:0;overflow:hidden;pointer-events:none'
  svg.innerHTML = buildFilterSVG()
  document.body.prepend(svg)
}

// ── Mouse-tracked specular highlight ─────────────────────────────────────────
// Writes --hl-x / --hl-y on :root once per animation frame.
// AbortController ensures only one listener exists — safe to call on every
// Astro page transition without stacking handlers.
let _trackingController: AbortController | null = null

function initHighlightTracking(): void {
  _trackingController?.abort()

  if (REDUCED_MOTION) return  // Skip mouse glow for accessibility

  _trackingController = new AbortController()
  const { signal } = _trackingController
  const root = document.documentElement

  let raf = 0
  document.addEventListener(
    'pointermove',
    (e: PointerEvent) => {
      cancelAnimationFrame(raf)
      raf = requestAnimationFrame(() => {
        root.style.setProperty('--hl-x', `${((e.clientX / innerWidth)  * 100).toFixed(1)}%`)
        root.style.setProperty('--hl-y', `${((e.clientY / innerHeight) * 100).toFixed(1)}%`)
      })
    },
    { passive: true, signal },
  )
}

// ── Init ─────────────────────────────────────────────────────────────────────
injectFilter()
initHighlightTracking()

// Re-run on Astro SPA navigation (filter may have been removed with old body)
document.addEventListener('astro:page-load', () => {
  injectFilter()
  // Tracking listener already persists — AbortController survives navigation
})
