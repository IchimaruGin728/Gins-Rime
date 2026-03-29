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

  const href = 'https://rime.ichimarugin728.dev/releases/latest/gins-rime'

  return (
    <div class="download-block">
      <a class="download-btn" href={href} download="gins-rime">
        下载 gins-rime CLI
      </a>
      {meta?.date && (
        <span class="download-meta">
          {meta.date}{meta.sha ? ` · ${meta.sha}` : ''}
        </span>
      )}
      <pre class="install-cmd">{'curl -fsSL ' + href + ' -o gins-rime && chmod +x gins-rime'}</pre>
    </div>
  )
}
