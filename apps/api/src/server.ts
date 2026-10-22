import "dotenv/config";
import Fastify from "fastify";
import helmet from "@fastify/helmet";
import cors from "@fastify/cors";
import { z } from "zod";
import { canTransitionCase, type CaseStatus } from "../../../modules/workflow/state-machine.js";

const app = Fastify({
  logger: {
    redact: [
      "req.headers.authorization",
      "req.headers.cookie",
      "req.body.apiKey",
      "req.body.password",
      "req.body.applicationPassword",
      "req.body.secret"
    ]
  },
  requestIdHeader: "x-request-id"
});

await app.register(helmet);
await app.register(cors, {
  origin: false, // Configure explicit trusted UI origins before browser use.
  credentials: true
});

const CreateCaseSchema = z.object({
  title: z.string().trim().min(1).max(300),
  submitted_context: z.string().max(100_000),
  source_notes: z.string().max(50_000).optional(),
  language_code: z.string().default("bn"),
  sensitivity_flags: z.array(z.string().max(80)).max(30).default([])
});

app.get("/health", async () => ({
  status: "ok",
  service: "ai-newsroom-api",
  readiness: "scaffold-only"
}));

app.post("/api/v1/cases", async (request, reply) => {
  const parsed = CreateCaseSchema.safeParse(request.body);
  if (!parsed.success) {
    return reply.code(400).send({
      error: {
        code: "VALIDATION_ERROR",
        message: "Request body failed validation.",
        details: parsed.error.flatten(),
        request_id: request.id,
        retryable: false
      }
    });
  }

  // TODO: require authenticated user and resource-level permission.
  // TODO: persist case + revision in one DB transaction.
  // TODO: calculate content hash on the server.
  // This scaffold intentionally does not pretend to persist data.
  return reply.code(501).send({
    error: {
      code: "NOT_IMPLEMENTED",
      message: "Database persistence is not wired in this scaffold.",
      details: {},
      request_id: request.id,
      retryable: false
    }
  });
});

app.post("/api/v1/workflows/:workflowId/transitions", async (request, reply) => {
  const schema = z.object({
    current: z.enum(["draft","queued","running","review_required","approved","publishing","published","publish_failed","blocked","cancelled"]),
    next: z.enum(["draft","queued","running","review_required","approved","publishing","published","publish_failed","blocked","cancelled"])
  });
  const parsed = schema.safeParse(request.body);
  if (!parsed.success) {
    return reply.code(400).send({
      error: { code: "VALIDATION_ERROR", message: "Invalid state transition request.", details: parsed.error.flatten(), request_id: request.id, retryable: false }
    });
  }
  if (!canTransitionCase(parsed.data.current as CaseStatus, parsed.data.next as CaseStatus)) {
    return reply.code(409).send({
      error: { code: "INVALID_STATE_TRANSITION", message: "The requested workflow transition is not allowed.", details: {}, request_id: request.id, retryable: false }
    });
  }
  // TODO: fetch persisted state under transaction/lock; never trust client-supplied current state.
  return reply.code(501).send({
    error: { code: "NOT_IMPLEMENTED", message: "Persistence and authorization are not wired in this scaffold.", details: {}, request_id: request.id, retryable: false }
  });
});

const host = process.env.API_HOST ?? "127.0.0.1";
const port = Number(process.env.API_PORT ?? "4100");
await app.listen({ host, port });
