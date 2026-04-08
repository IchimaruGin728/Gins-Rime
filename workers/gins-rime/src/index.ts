import {
  WorkflowEntrypoint,
  WorkflowEvent,
  WorkflowStep,
} from "cloudflare:workers";

interface Env {
  BUCKET: R2Bucket;
  BUILD_QUEUE: Queue;
  DICT_UPDATE_WORKFLOW: Workflow;
  ASSETS: Fetcher;
  GITHUB_REPO: string;
}

interface DictUpdateParams {
  dict: string;
  r2Key: string;
  date: string;
  lines?: number;
  triggeredBy?: string;
}

interface SchemeUpdateParams {
  version: string;
  r2Key: string;
  triggeredBy?: string;
}

const CORS_HEADERS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, HEAD, POST, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization",
};

export class DictUpdateWorkflow extends WorkflowEntrypoint<Env, DictUpdateParams> {
  async run(event: WorkflowEvent<DictUpdateParams>, step: WorkflowStep) {
    const { dict, r2Key, date, lines, triggeredBy } = event.payload;

    const meta = await step.do(
      "validate-r2-object",
      { retries: { limit: 5, delay: "10 seconds", backoff: "exponential" } },
      async () => {
        const obj = await this.env.BUCKET.head(r2Key);
        if (!obj) throw new Error(`R2 object not found: ${r2Key}`);
        return { size: obj.size, etag: obj.httpEtag };
      }
    );

    await step.do(
      "update-metadata",
      async () => {
        await updateMetadata(this.env.BUCKET, dict, {
          date,
          url: `/${r2Key}`,
          ...(lines && { lines }),
          size: meta.size,
          etag: meta.etag,
          triggeredBy: triggeredBy ?? "workflow",
        });
      }
    );

    await step.do(
      "enqueue-notification",
      async () => {
        await this.env.BUILD_QUEUE.send({
          type: "dict-updated",
          dict,
          r2Key,
          date,
          lines,
          triggeredBy: triggeredBy ?? "workflow",
        });
      }
    );

    return { dict, date, size: meta.size };
  }
}

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    if (request.method === "OPTIONS") {
      return new Response(null, { headers: CORS_HEADERS });
    }

    const url = new URL(request.url);
    const path = url.pathname;

    try {
      if (path === "/health") return json({ ok: true });

      if (path === "/version") {
        const obj = await env.BUCKET.get("releases/latest.json");
        if (!obj) return json({ version: "0.1.0" });
        return new Response(obj.body, {
          headers: { ...CORS_HEADERS, "Content-Type": "application/json", "Cache-Control": "public, max-age=300" },
        });
      }

      if (path === "/api/status") {
        const [versionObj, cliObj] = await Promise.all([
          env.BUCKET.get("releases/latest.json"),
          env.BUCKET.get("cli/meta.json"),
        ]);
        const version = versionObj ? JSON.parse(await versionObj.text()) : {};
        const cli = cliObj ? JSON.parse(await cliObj.text()) : {};
        return json({ ...version, cli });
      }

      if (path.startsWith("/dicts/")) {
        return serveR2(env.BUCKET, `dicts/${path.slice(7)}`);
      }

      if (path.startsWith("/releases/")) {
        return serveR2(env.BUCKET, path.slice(1));
      }

      if (path === "/workflow/dict-update" && request.method === "POST") {
        if (!isAuthorized(request)) return json({ error: "unauthorized" }, 401);

        const body = await request.json<DictUpdateParams>();
        if (!body.dict || !body.r2Key || !body.date) return json({ error: "missing fields" }, 400);

        const instance = await env.DICT_UPDATE_WORKFLOW.create({
          id: `dict-update-${body.dict}-${body.date}-${Date.now()}`,
          params: body,
        });
        return json({ instanceId: instance.id, status: "queued" });
      }

      if (path === "/api/scheme-update" && request.method === "POST") {
        if (!isAuthorized(request)) return json({ error: "unauthorized" }, 401);

        const body = await request.json<SchemeUpdateParams>();
        if (!body.version || !body.r2Key) return json({ error: "missing fields" }, 400);

        await updateMetadata(env.BUCKET, "scheme", {
          version: body.version,
          url: `/${body.r2Key}`,
          triggeredBy: body.triggeredBy ?? "api",
        });

        return json({ ok: true, version: body.version });
      }

      if (path.startsWith("/workflow/") && request.method === "GET") {
        const instance = await env.DICT_UPDATE_WORKFLOW.get(path.slice(10));
        return json({ id: instance.id, status: await instance.status() });
      }

      return env.ASSETS.fetch(request);
    } catch (e) {
      return json({ error: "internal_error", message: e instanceof Error ? e.message : String(e) }, 500);
    }
  },

  async queue(batch: MessageBatch, env: Env): Promise<void> {
    for (const msg of batch.messages) {
      const body = msg.body as any;
      console.log(`[queue] ${body.type}: ${body.dict} @ ${body.date}`);
      msg.ack();
    }
  },
} satisfies ExportedHandler<Env>;

async function updateMetadata(bucket: R2Bucket, key: string, val: any) {
  const existing = await bucket.get("releases/latest.json");
  const data = existing ? JSON.parse(await existing.text()) : {};
  data[key] = { ...val, updatedAt: new Date().toISOString() };
  await bucket.put("releases/latest.json", JSON.stringify(data, null, 2), {
    httpMetadata: { contentType: "application/json" }
  });
}

function isAuthorized(req: Request): boolean {
  const auth = req.headers.get("Authorization");
  return !!auth?.startsWith("Bearer ");
}

async function serveR2(bucket: R2Bucket, key: string): Promise<Response> {
  const obj = await bucket.get(key);
  if (!obj) return json({ error: "not found" }, 404);

  const ext = key.split(".").pop();
  const contentType = ext === "yaml" ? "text/yaml" : ext === "json" ? "application/json" : ext === "gz" ? "application/gzip" : "application/octet-stream";

  return new Response(obj.body, {
    headers: {
      ...CORS_HEADERS,
      "Content-Type": contentType,
      "Content-Disposition": `attachment; filename="${key.split("/").pop()}"`,
      "ETag": obj.httpEtag,
      "Cache-Control": "public, max-age=3600",
    },
  });
}

function json(data: any, status: number = 200): Response {
  return Response.json(data, { status, headers: CORS_HEADERS });
}
