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

const CLI_HREF = '/releases/latest/gins-rime'
const INSTALL_CMD = `curl -fsSL ${CLI_HREF} -o gins-rime && chmod +x gins-rime`

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
    <div class="space-y-4">
      <div class="grid grid-cols-1 gap-3 md:grid-cols-2 xl:grid-cols-3">
        {DICTS.map(({ key, name, sub }) => {
          const info = status?.[key as keyof ApiStatus] as DictInfo | undefined
          const ver = dictVersions[key] !== '—' ? dictVersions[key] : (info?.date ?? '—')
          const hasLines = !loading && info?.lines != null
          return (
            <div
              key={key}
              class="surface-card"
            >
              <span class="surface-title">{name}</span>
              <span class="surface-sub">{sub}</span>
              
              <div class="mt-4 flex flex-col gap-1">
                <span class="surface-meta">
                  {loading ? '…' : ver}
                </span>
                <span class={`surface-meta-muted${hasLines ? '' : ' invisible'}`}>
                  {info?.lines != null ? `${info.lines.toLocaleString()} entries` : '0 entries'}
                </span>
              </div>
            </div>
          )
        })}
      </div>

      <div class="surface-card md:p-5">
        <div class="flex flex-col gap-3 md:flex-row md:items-center md:justify-between">
          <div class="min-w-0">
            <span class="block text-lg font-semibold text-[var(--sl-color-white)]">Gin's-Rime CLI</span>
            {status?.cli?.date && (
              <span class="mt-1 block surface-meta-muted">
                {status.cli.date}{status.cli.sha ? ` · ${status.cli.sha}` : ''}
              </span>
            )}
          </div>
          <a
            class="primary-btn"
            href={CLI_HREF}
            download="gins-rime"
          >
            下载
          </a>
        </div>

        <pre class="mt-4 overflow-x-auto rounded-xl border border-[var(--sl-color-hairline)] bg-black/20 px-4 py-3 text-xs text-[var(--sl-color-gray-2)]">{INSTALL_CMD}</pre>
      </div>
    </div>
  )
}
