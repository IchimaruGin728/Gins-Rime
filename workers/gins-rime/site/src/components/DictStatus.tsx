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
      <div class="my-6 grid grid-cols-[repeat(auto-fit,minmax(180px,1fr))] gap-4">
        {Object.keys(DICT_LABELS).map(k => (
          <div key={k} class="surface-card h-[4.5rem] animate-pulse" />
        ))}
      </div>
    )
  }

  return (
    <div class="my-6 grid grid-cols-[repeat(auto-fit,minmax(180px,1fr))] items-stretch gap-4">
      {Object.entries(DICT_LABELS).map(([key, label]) => {
        const info = data[key as keyof VersionData]
        return (
          <div key={key} class="surface-card box-border flex h-full min-h-[4.5rem] flex-col gap-1">
            <span class="text-[0.9rem] font-semibold text-[var(--sl-color-white)]">{label}</span>
            <span class="tabular-nums surface-meta">
              {info?.date ?? '—'}
            </span>
            {info?.lines != null && (
              <span class="text-xs text-[var(--sl-color-gray-3)]">
                {info.lines.toLocaleString()} 条
              </span>
            )}
          </div>
        )
      })}
    </div>
  )
}
