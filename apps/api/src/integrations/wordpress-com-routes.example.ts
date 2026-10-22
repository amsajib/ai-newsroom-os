/**
 * Fastify wiring example. Register only after implementing real auth/RBAC,
 * audit persistence and secret-manager access. This example has no publish route.
 */
import type { FastifyInstance } from "fastify";
import { z } from "zod";
import { WordPressComAdapter } from "./wordpress-com-adapter.js";

const DraftSchema = z.object({
  title: z.string().trim().min(1).max(300),
  content: z.string().min(1).max(100000),
  excerpt: z.string().max(5000).optional(),
  slug: z.string().max(200).optional(),
  categories: z.array(z.number().int().positive()).max(50).optional(),
  tags: z.array(z.number().int().positive()).max(100).optional(),
  confirmDraftCreation: z.literal(true)
});
type Deps = {
  requireAdmin: (request: any, reply: any) => Promise<void>;
  requireEditor: (request: any, reply: any) => Promise<void>;
  getTokenFromSecretStore: () => Promise<string>;
  audit: (action: string, outcome: string, metadata: Record<string, unknown>) => Promise<void>;
};
export async function registerWpComRoutes(app: FastifyInstance, deps: Deps) {
  const site = process.env.WP_COM_SITE;
  if (!site) throw new Error("WP_COM_SITE_REQUIRED");
  const client = async () => new WordPressComAdapter(site, await deps.getTokenFromSecretStore());

  app.post("/api/v1/integrations/cms/wordpress-com/test",
    { preHandler: deps.requireAdmin }, async (req: any, reply) => {
      try {
        const result = await (await client()).testConnection();
        await deps.audit("cms.connection_test", "success", { site, checkedAt: result.checkedAt });
        return { connection_status: "success", site: result.site, tested_at: result.checkedAt };
      } catch (e: any) {
        await deps.audit("cms.connection_test", "failed", { site, safeCode: e?.code ?? "UNKNOWN" });
        return reply.code(e?.status === 401 ? 401 : 502).send({
          error: { code: e?.code ?? "CMS_CONNECTION_FAILED", message: "WordPress.com connection test failed.",
            request_id: req.id, retryable: Boolean(e?.retryable) }
        });
      }
    });

  app.post("/api/v1/integrations/cms/wordpress-com/drafts",
    { preHandler: deps.requireEditor }, async (req: any, reply) => {
      const parsed = DraftSchema.safeParse(req.body);
      if (!parsed.success) return reply.code(400).send({
        error: { code: "VALIDATION_ERROR", message: "Invalid draft request.",
          details: parsed.error.flatten(), request_id: req.id, retryable: false }
      });
      try {
        const { confirmDraftCreation, ...input } = parsed.data;
        const post = await (await client()).createDraft(input);
        await deps.audit("cms.draft_create", "success", { site, externalPostId: post.ID ?? post.id, status: post.status });
        const id = post.ID ?? post.id;
        return reply.code(201).send({
          status: post.status, external_post_id: id,
          edit_url: `https://${site}/wp-admin/post.php?post=${id}&action=edit`,
          preview_url: post.URL ? `${post.URL}${post.URL.includes("?") ? "&" : "?"}preview=true` : undefined
        });
      } catch (e: any) {
        await deps.audit("cms.draft_create", "failed", { site, safeCode: e?.code ?? "UNKNOWN" });
        return reply.code(e?.status === 401 ? 401 : 502).send({
          error: { code: e?.code ?? "CMS_DRAFT_CREATE_FAILED", message: "WordPress.com draft creation failed.",
            request_id: req.id, retryable: Boolean(e?.retryable) }
        });
      }
    });
}
