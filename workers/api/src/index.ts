import {
  WorkflowEntrypoint,
  WorkflowEvent,
  WorkflowStep,
} from "cloudflare:workers";

// ── Types ─────────────────────────────────────────────────────

interface Env {
  BUCKET: R2Bucket;
  BUILD_QUEUE: Queue;
  DICT_UPDATE_WORKFLOW: Workflow;
  GITHUB_REPO: string;
}

interface DictUpdateParams {
  dict: string;          // e.g. "zhwiki" | "tone_moe"
  r2Key: string;         // e.g. "dicts/zhwiki.dict.yaml"
  date: string;          // e.g. "20260328"
  lines?: number;
  triggeredBy?: string;  // "github-actions" | "manual"
}

// ── Workflow ──────────────────────────────────────────────────
//
// Triggered after GitHub Actions uploads a built dict to R2.
// Steps:
//   1. Validate the R2 object exists and has content
//   2. Update releases/latest.json
//   3. Enqueue notification to BUILD_QUEUE

export class DictUpdateWorkflow extends WorkflowEntrypoint<Env, DictUpdateParams> {
  async run(event: WorkflowEvent<DictUpdateParams>, step: WorkflowStep) {
    const { dict, r2Key, date, lines, triggeredBy } = event.payload;

    // Step 1: Validate R2 object
    const meta = await step.do(
      "validate-r2-object",
      { retries: { limit: 5, delay: "10 seconds", backoff: "exponential" }, timeout: "2 minutes" },
      async () => {
        const obj = await this.env.BUCKET.head(r2Key);
        if (!obj) throw new Error(`R2 object not found: ${r2Key}`);
        return { size: obj.size, etag: obj.httpEtag };
      }
    );

    // Step 2: Update latest.json
    await step.do(
      "update-latest-json",
      { retries: { limit: 3, delay: "5 seconds" } },
      async () => {
        const existing = await this.env.BUCKET.get("releases/latest.json");
        const data: Record<string, unknown> = existing
          ? JSON.parse(await existing.text())
          : {};

        data[dict] = {
          date,
          url: `/${r2Key}`,
          ...(lines && { lines }),
          size: meta.size,
          etag: meta.etag,
          updatedAt: new Date().toISOString(),
        };

        await this.env.BUCKET.put(
          "releases/latest.json",
          JSON.stringify(data, null, 2),
          { httpMetadata: { contentType: "application/json" } }
        );
      }
    );

    // Step 3: Enqueue notification
    await step.do(
      "enqueue-notification",
      { retries: { limit: 2, delay: "3 seconds" } },
      async () => {
        await this.env.BUILD_QUEUE.send({
          type: "dict-updated",
          dict,
          r2Key,
          date,
          lines,
          triggeredBy: triggeredBy ?? "unknown",
        });
      }
    );

    return { dict, date, size: meta.size };
  }
}

// ── Worker ────────────────────────────────────────────────────

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, HEAD, POST, OPTIONS",
};

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    if (request.method === "OPTIONS") {
      return new Response(null, { headers: CORS });
    }

    const url = new URL(request.url);
    const path = url.pathname;

    try {
      // GET /health
      if (path === "/health") {
        return json({ ok: true }, CORS);
      }

      // GET /version  —  latest.json from R2
      if (path === "/version") {
        const obj = await env.BUCKET.get("releases/latest.json");
        if (!obj) return json({ version: "0.1.0" }, CORS);
        return new Response(obj.body, {
          headers: { ...CORS, "Content-Type": "application/json", "Cache-Control": "public, max-age=300" },
        });
      }

      // GET /dicts/:name
      if (path.startsWith("/dicts/")) {
        return serveR2(env.BUCKET, `dicts/${path.slice(7)}`, CORS);
      }

      // GET /releases/:version/:file
      if (path.startsWith("/releases/")) {
        return serveR2(env.BUCKET, path.slice(1), CORS);
      }

      // POST /workflow/dict-update  —  trigger DictUpdateWorkflow
      // Called by GitHub Actions after uploading to R2
      if (path === "/workflow/dict-update" && request.method === "POST") {
        const auth = request.headers.get("Authorization");
        if (!auth?.startsWith("Bearer ")) {
          return json({ error: "unauthorized" }, { ...CORS, status: 401 });
        }

        const body = await request.json<DictUpdateParams>();
        if (!body.dict || !body.r2Key || !body.date) {
          return json({ error: "missing fields: dict, r2Key, date" }, { ...CORS, status: 400 });
        }

        const instance = await env.DICT_UPDATE_WORKFLOW.create({
          id: `dict-update-${body.dict}-${body.date}`,
          params: body,
        });

        return json({ instanceId: instance.id, status: "queued" }, CORS);
      }

      // GET /workflow/:id  —  check workflow instance status
      if (path.startsWith("/workflow/") && request.method === "GET") {
        const id = path.slice(10);
        const instance = await env.DICT_UPDATE_WORKFLOW.get(id);
        const status = await instance.status();
        return json({ id, status }, CORS);
      }

      return json(
        {
          endpoints: [
            "GET  /health",
            "GET  /version",
            "GET  /dicts/{name}",
            "GET  /releases/{version}/{file}",
            "POST /workflow/dict-update",
            "GET  /workflow/{id}",
          ],
        },
        { ...CORS, status: 404 }
      );
    } catch (e) {
      return json({ error: "internal error" }, { ...CORS, status: 500 });
    }
  },

  // Queue consumer: process build notifications
  async queue(batch: MessageBatch, env: Env): Promise<void> {
    for (const msg of batch.messages) {
      const body = msg.body as Record<string, unknown>;
      console.log(`[queue] ${body.type}: ${body.dict} @ ${body.date}`);
      // TODO: Push notification / webhook to user
      msg.ack();
    }
  },
} satisfies ExportedHandler<Env>;

// ── Helpers ───────────────────────────────────────────────────

async function serveR2(
  bucket: R2Bucket,
  key: string,
  headers: Record<string, string>
): Promise<Response> {
  const obj = await bucket.get(key);
  if (!obj) return json({ error: "not found", key }, { ...headers, status: 404 });

  const ext = key.split(".").pop();
  const contentType =
    ext === "yaml" ? "text/yaml" :
    ext === "json" ? "application/json" :
    ext === "gz"   ? "application/gzip" :
    "application/octet-stream";

  return new Response(obj.body, {
    headers: {
      ...headers,
      "Content-Type": contentType,
      "Content-Disposition": `attachment; filename="${key.split("/").pop()}"`,
      "ETag": obj.httpEtag,
      "Cache-Control": "public, max-age=3600",
    },
  });
}

function json(
  data: unknown,
  headersOrOpts: Record<string, string | number> = {}
): Response {
  const { status = 200, ...headers } = headersOrOpts as Record<string, string | number>;
  return Response.json(data, { status: status as number, headers: headers as Record<string, string> });
}
