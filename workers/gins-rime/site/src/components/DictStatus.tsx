import { useEffect, useState } from 'preact/hooks'

interface DictInfo {
  date?: string
  lines?: number
}

interface VersionData {
  zhwiki?: DictInfo
  tone_moe?: DictInfo
  'gins-shici'?: DictInfo
}

const DICT_LABELS: Record<string, string> = {
  zhwiki:      '维基百科标题',
  tone_moe:    '萌娘百科',
  'gins-shici': '古诗词补充',
}

export default function DictStatus() {
  const [data, setData] = useState<VersionData | null>(null)
  const [error, setError] = useState(false)

  useEffect(() => {
    fetch('/api/status')
      .then(r => r.json())
      .then(setData)
      .catch(() => setError(true))
  }, [])

  if (error) {
    return <p class="text-sm opacity-60">无法获取词库状态</p>
  }

  if (!data) {
    return (
      <div class="grid gap-4 my-6" style="grid-template-columns:repeat(auto-fit,minmax(180px,1fr))">
        {Object.keys(DICT_LABELS).map(k => (
          <div key={k} class="dict-card skeleton" />
        ))}
      </div>
    )
  }

  return (
    <div class="grid gap-4 my-6" style="grid-template-columns:repeat(auto-fit,minmax(180px,1fr)); align-items:stretch">
      {Object.entries(DICT_LABELS).map(([key, label]) => {
        const info = data[key as keyof VersionData]
        return (
          <div key={key} class="dict-card flex flex-col gap-1 p-4 h-full min-h-[4.5rem] box-border">
            <span class="font-semibold text-[0.9rem] text-[var(--sl-color-text)]">{label}</span>
            <span class="text-[0.8rem] tabular-nums text-[var(--sl-color-text-accent)]">
              {info?.date ?? '—'}
            </span>
            {info?.lines != null && (
              <span class="text-[0.75rem] text-[color-mix(in_srgb,var(--sl-color-text)_55%,transparent)]">
                {info.lines.toLocaleString()} 条
              </span>
            )}
          </div>
        )
      })}
    </div>
  )
}
