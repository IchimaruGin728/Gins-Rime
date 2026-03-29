import { useEffect, useState } from 'preact/hooks'

interface DictInfo { date?: string; lines?: number }
interface ApiStatus {
  zhwiki?: DictInfo
  tone_moe?: DictInfo
  'gins-shici'?: DictInfo
  cli?: { date?: string; sha?: string }
}

interface Props {
  dictVersions: Record<string, string>
}

const DICTS: { key: string; name: string; sub: string }[] = [
  { key: 'zhwiki',      name: '维基百科标题', sub: '中文 Wikipedia' },
  { key: 'tone_moe',    name: '萌娘百科',     sub: '二次元词汇' },
  { key: 'gins-shici',  name: '古诗词',       sub: 'chinese-poetry' },
]

const CLI_HREF = 'https://rime.ichimarugin728.dev/releases/latest/gins-rime'
const INSTALL_CMD = `curl -fsSL ${CLI_HREF} -o gins-rime && chmod +x gins-rime`

const CARD_BASE = [
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
    <div style="display:flex;flex-direction:column;gap:0.6rem">

      {/* ── Dict cards — own grid, align-items:stretch so all same height ── */}
      <div style="display:grid;grid-template-columns:repeat(3,1fr);gap:0.6rem;align-items:stretch">
        {DICTS.map(({ key, name, sub }) => {
          const info = status?.[key as keyof ApiStatus] as DictInfo | undefined
          const ver = dictVersions[key] !== '—' ? dictVersions[key] : (info?.date ?? '—')
          return (
            <div key={key} style={`display:flex;flex-direction:column;gap:0.18rem;padding:0.85rem 1rem;${CARD_BASE}`}>
              <span style="font-weight:600;font-size:0.875rem;color:var(--sl-color-text)">{name}</span>
              <span style="font-size:0.68rem;color:color-mix(in srgb,var(--sl-color-text) 42%,transparent)">{sub}</span>
              <span style="font-size:0.78rem;font-family:var(--sl-font-mono);font-variant-numeric:tabular-nums;color:var(--sl-color-text-accent);margin-top:auto;padding-top:0.4rem">
                {loading ? '…' : ver}
              </span>
              <span style={`font-size:0.68rem;color:color-mix(in srgb,var(--sl-color-text) 38%,transparent);font-variant-numeric:tabular-nums;visibility:${!loading && info?.lines != null ? 'visible' : 'hidden'}`}>
                {info?.lines != null ? `${info.lines.toLocaleString()} 条` : '0 条'}
              </span>
            </div>
          )
        })}
      </div>

      {/* ── CLI — full-width bar, horizontal layout ── */}
      <div style={`display:grid;grid-template-columns:1fr auto;align-items:center;gap:0.75rem 1.25rem;padding:0.85rem 1rem;${CARD_BASE}`}>
        {/* Left: name + version */}
        <div style="display:flex;align-items:baseline;gap:0.5rem;flex-wrap:wrap;min-width:0">
          <span style="font-weight:600;font-size:0.875rem;color:var(--sl-color-text);white-space:nowrap">Gin's-Rime CLI</span>
          {status?.cli?.date && (
            <span style="font-size:0.7rem;font-family:var(--sl-font-mono);color:color-mix(in srgb,var(--sl-color-text) 42%,transparent);font-variant-numeric:tabular-nums;white-space:nowrap">
              {status.cli.date}{status.cli.sha ? ` · ${status.cli.sha}` : ''}
            </span>
          )}
        </div>

        {/* Right: download button */}
        <a
          class="download-btn"
          href={CLI_HREF}
          download="gins-rime"
          style="font-size:0.78rem;padding:0.35rem 0.9rem;white-space:nowrap"
        >
          下载
        </a>

        {/* Bottom: install command, spans both columns */}
        <pre style={[
          'grid-column:1/-1',
          'margin:0',
          'font-size:0.7rem',
          'font-family:var(--sl-font-mono)',
          'overflow-x:auto',
          'padding:0.45rem 0.7rem',
          'border-radius:var(--sl-border-radius-sm,8px)',
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
