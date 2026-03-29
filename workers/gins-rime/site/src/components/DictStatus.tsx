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
  zhwiki: '维基百科标题',
  tone_moe: '萌娘百科',
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
    return <p class="dict-status-error">无法获取词库状态</p>
  }

  if (!data) {
    return (
      <div class="dict-status-grid loading">
        {Object.keys(DICT_LABELS).map(k => (
          <div key={k} class="dict-card skeleton" />
        ))}
      </div>
    )
  }

  return (
    <div class="dict-status-grid">
      {Object.entries(DICT_LABELS).map(([key, label]) => {
        const info = data[key as keyof VersionData]
        return (
          <div key={key} class="dict-card">
            <span class="dict-name">{label}</span>
            <span class="dict-date">{info?.date ?? '—'}</span>
            {info?.lines && (
              <span class="dict-lines">{info.lines.toLocaleString()} 条</span>
            )}
          </div>
        )
      })}
    </div>
  )
}
