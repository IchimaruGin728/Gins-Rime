import type { APIRoute } from 'astro'

export const prerender = false

export const GET: APIRoute = async ({ locals }) => {
  const env = locals.runtime?.env as { API_BASE?: string } | undefined
  const apiBase = env?.API_BASE ?? 'https://gins-rime-api.ichimarugin728.workers.dev'

  const [versionRes, cliRes] = await Promise.allSettled([
    fetch(`${apiBase}/version`),
    fetch(`${apiBase}/cli/meta.json`),
  ])

  const version = versionRes.status === 'fulfilled' && versionRes.value.ok
    ? await versionRes.value.json()
    : {}

  const cli = cliRes.status === 'fulfilled' && cliRes.value.ok
    ? await cliRes.value.json()
    : {}

  return Response.json({ ...version, cli })
}
