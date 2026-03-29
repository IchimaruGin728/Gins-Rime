import { useEffect, useState } from 'preact/hooks'

interface DictInfo { date?: string; lines?: number }
interface ApiStatus {
  zhwiki?: DictInfo
  tone_moe?: DictInfo
  'gins-shici'?: DictInfo
  cli?: { date?: string; sha?: string }
}

interface Props {
  /** Upstream version tags read at build-time from .upstream/ files */
  dictVersions: Record<string, string>
}

const DICTS: { key: string; name: string; sub: string }[] = [
  { key: 'zhwiki',      name: '维基百科标题', sub: '中文 Wikipedia' },
  { key: 'tone_moe',    name: '萌娘百科',     sub: '二次元词汇' },
  { key: 'gins-shici',  name: '古诗词',       sub: 'chinese-poetry' },
]

const CLI_HREF = 'https://rime.ichimarugin728.dev/releases/latest/gins-rime'
const INSTALL_CMD = `curl -fsSL ${CLI_HREF} -o gins-rime && chmod +x gins-rime`

// Shared card base style (keeps TSX DRY)
const CARD = [
  'display:flex',
  'flex-direction:column',
  'gap:0.18rem',
  'padding:0.85rem 1rem',
  'min-height:4.5rem',
  'border-radius:var(--sl-border-radius-sm,8px)',
  'border:1px solid var(--sl-color-hairline)',
  'background:color-mix(in srgb,var(--sl-color-accent) 4%,transparent)',
  'contain:layout style',
].join(';')

export default function HomeStatusPanel({ dictVersions }: Props) {
  const [status, setStatus] = useState<ApiStatus | null>(null)

  useEffect(() => {
    fetch('/api/status')
      .then(r => r.json())
      .then(setStatus)
      .catch(() => setStatus({}))
  }, [])

  const loading = status === null

  return (
    // align-items:start → each card sizes to its own content, CLI card
    // won't stretch the shorter dict cards
    <div
      class="panel-grid"
      style="display:grid;grid-template-columns:repeat(5,1fr);gap:0.6rem;align-items:start"
    >
      {/* ── Dict cards (3 × 1fr) ── */}
      {DICTS.map(({ key, name, sub }) => {
        const info = status?.[key as keyof ApiStatus] as DictInfo | undefined
        // Prefer upstream version tag; fall back to API build date
        const ver = dictVersions[key] !== '—' ? dictVersions[key] : (info?.date ?? '—')
        return (
          <div key={key} style={CARD}>
            <span style="font-weight:600;font-size:0.875rem;color:var(--sl-color-text)">{name}</span>
            <span style="font-size:0.68rem;color:color-mix(in srgb,var(--sl-color-text) 42%,transparent)">{sub}</span>
            <span style="font-size:0.78rem;font-family:var(--sl-font-mono);font-variant-numeric:tabular-nums;color:var(--sl-color-text-accent);margin-top:auto;padding-top:0.4rem">
              {loading ? '…' : ver}
            </span>
            {!loading && info?.lines != null && (
              <span style="font-size:0.68rem;color:color-mix(in srgb,var(--sl-color-text) 38%,transparent);font-variant-numeric:tabular-nums">
                {info.lines.toLocaleString()} 条
              </span>
            )}
          </div>
        )
      })}

      {/* ── CLI card (span 2) ── */}
      <div style={`grid-column:span 2;${CARD};gap:0.55rem`}>
        {/* Name row */}
        <div style="display:flex;align-items:center;justify-content:space-between;gap:0.5rem;flex-wrap:wrap">
          <span style="font-weight:600;font-size:0.875rem;color:var(--sl-color-text)">Gin's-Rime CLI</span>
          {status?.cli?.date && (
            <span style="font-size:0.7rem;font-family:var(--sl-font-mono);color:color-mix(in srgb,var(--sl-color-text) 42%,transparent);font-variant-numeric:tabular-nums">
              {status.cli.date}{status.cli.sha ? ` · ${status.cli.sha}` : ''}
            </span>
          )}
        </div>

        {/* Download button */}
        <a
          class="download-btn"
          href={CLI_HREF}
          download="gins-rime"
          style="font-size:0.78rem;padding:0.35rem 0.9rem;align-self:flex-start"
        >
          下载
        </a>

        {/* Install command — theme-aware background, no dark scrollbar surprise */}
        <pre style={[
          'margin:0',
          'font-size:0.7rem',
          'font-family:var(--sl-font-mono)',
          'overflow-x:auto',
          'padding:0.45rem 0.7rem',
          'border-radius:var(--sl-border-radius-sm,8px)',
          // Use sidebar bg so it looks correct in both light and dark mode
          'background:var(--sl-color-bg-sidebar)',
          'border:1px solid var(--sl-color-hairline)',
          'white-space:pre',
          'line-height:1.5',
          'color:color-mix(in srgb,var(--sl-color-text) 65%,transparent)',
        ].join(';')}>{INSTALL_CMD}</pre>
      </div>
    </div>
  )
}
