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
      <a class="download-btn" href={href} download="gins-rime">
        下载 gins-rime CLI
      </a>
      {meta?.date && (
        <span class="text-[0.8rem] tabular-nums text-[color-mix(in_srgb,var(--sl-color-text)_55%,transparent)]">
          {meta.date}{meta.sha ? ` · ${meta.sha}` : ''}
        </span>
      )}
      <pre class="text-[0.85rem] overflow-x-auto px-4 py-3 rounded-[var(--sl-border-radius-sm)] bg-white/5 border border-white/8 font-mono">
        {'curl -fsSL ' + href + ' -o gins-rime && chmod +x gins-rime'}
      </pre>
    </div>
  )
}
