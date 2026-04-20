import { useEffect, useState } from 'preact/hooks'

interface CliMeta {
  sha?: string
  date?: string
}

export default function DownloadBtn() {
  const [meta, setMeta] = useState<CliMeta | null>(null)

  useEffect(() => {
    fetch('/api/status')
      .then(r => r.json())
      .then(d => setMeta(d.cli))
      .catch(() => {})
  }, [])

  const href = '/releases/latest/gins-rime'

  return (
    <div class="flex flex-col gap-3 my-6">
      <a class="primary-btn" href={href} download="gins-rime">
        下载 gins-rime CLI
      </a>
      {meta?.date && (
        <span class="surface-meta-muted tabular-nums">
          {meta.date}{meta.sha ? ` · ${meta.sha}` : ''}
        </span>
      )}
      <pre class="overflow-x-auto rounded-xl border border-[var(--sl-color-hairline)] bg-black/20 px-4 py-3 font-mono text-[0.85rem] text-[var(--sl-color-gray-2)]">
        {'curl -fsSL ' + href + ' -o gins-rime && chmod +x gins-rime'}
      </pre>
    </div>
  )
}
