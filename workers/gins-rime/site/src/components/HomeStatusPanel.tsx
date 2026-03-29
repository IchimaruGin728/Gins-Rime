import { useEffect, useState } from 'preact/hooks'

interface DictInfo { date?: string; lines?: number }
interface ApiStatus {
  zhwiki?: DictInfo
  tone_moe?: DictInfo
  'gins-shici'?: DictInfo
  cli?: { date?: string; sha?: string }
}

const DICTS: { key: string; name: string; sub: string }[] = [
  { key: 'zhwiki',     name: '维基百科标题', sub: '中文 Wikipedia' },
  { key: 'tone_moe',   name: '萌娘百科',     sub: '二次元专有名词' },
  { key: 'gins-shici', name: '古诗词',       sub: 'chinese-poetry' },
]

const CLI_HREF = 'https://rime.ichimarugin728.dev/releases/latest/gins-rime'
const INSTALL_CMD = `curl -fsSL ${CLI_HREF} -o gins-rime && chmod +x gins-rime`

export default function HomeStatusPanel() {
  const [status, setStatus] = useState<ApiStatus | null>(null)

  useEffect(() => {
    fetch('/api/status')
      .then(r => r.json())
      .then(setStatus)
      .catch(() => setStatus({}))
  }, [])

  const loading = status === null

  return (
    <div
      class="panel-grid"
      style="display:grid;grid-template-columns:repeat(5,1fr);gap:0.6rem"
    >
      {/* ── Dict cards (3 × 1fr) ── */}
      {DICTS.map(({ key, name, sub }) => {
        const info = status?.[key as keyof ApiStatus] as DictInfo | undefined
        return (
          <div
            key={key}
            class={`hp-card hp-static${loading ? ' hp-loading' : ''}`}
            style="display:flex;flex-direction:column;gap:0.18rem;padding:0.85rem 1rem;min-height:5rem;border-radius:var(--sl-border-radius-sm,8px);border:1px solid var(--sl-color-hairline);background:color-mix(in srgb,var(--sl-color-accent) 4%,transparent);contain:layout style"
          >
            <span style="font-weight:600;font-size:0.875rem;color:var(--sl-color-text)">{name}</span>
            <span style="font-size:0.68rem;color:color-mix(in srgb,var(--sl-color-text) 42%,transparent)">{sub}</span>
            <span style="font-size:0.78rem;font-family:var(--sl-font-mono);font-variant-numeric:tabular-nums;color:var(--sl-color-text-accent);margin-top:auto;padding-top:0.45rem">
              {loading ? '…' : (info?.date ?? '—')}
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
      <div
        style="grid-column:span 2;display:flex;flex-direction:column;gap:0.6rem;padding:0.85rem 1rem;min-height:5rem;border-radius:var(--sl-border-radius-sm,8px);border:1px solid var(--sl-color-hairline);background:color-mix(in srgb,var(--sl-color-accent) 4%,transparent);contain:layout style"
      >
        <div style="display:flex;align-items:baseline;gap:0.5rem;flex-wrap:wrap">
          <span style="font-weight:600;font-size:0.875rem;color:var(--sl-color-text)">gins-rime CLI</span>
          {status?.cli?.date && (
            <span style="font-size:0.72rem;font-family:var(--sl-font-mono);color:color-mix(in srgb,var(--sl-color-text) 42%,transparent);font-variant-numeric:tabular-nums">
              {status.cli.date}{status.cli.sha ? ` · ${status.cli.sha}` : ''}
            </span>
          )}
        </div>

        <a
          class="download-btn"
          href={CLI_HREF}
          download="gins-rime"
          style="font-size:0.82rem;padding:0.45rem 1rem"
        >
          下载
        </a>

        <pre style="margin:0;font-size:0.72rem;font-family:var(--sl-font-mono);overflow-x:auto;padding:0.5rem 0.75rem;border-radius:var(--sl-border-radius-sm,8px);background:rgba(255,255,255,0.05);border:1px solid rgba(255,255,255,0.07);white-space:pre;line-height:1.5;color:color-mix(in srgb,var(--sl-color-text) 70%,transparent)">{INSTALL_CMD}</pre>
      </div>
    </div>
  )
}
