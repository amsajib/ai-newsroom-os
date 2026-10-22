# UI API Binding Checklist

All routes below are illustrative contracts to bind to backend implementation. Never place provider API keys or CMS credentials in client-readable configuration.

| UI action | API contract | Required behavior |
|---|---|---|
| Create case | `POST /api/v1/cases` | Return case + initial revision IDs |
| Upload asset | `POST /api/v1/cases/{id}/assets` | Validate file and return asset ref |
| Start workflow | `POST /api/v1/cases/{id}/workflows` | Idempotent; return workflow ID |
| View claims | `GET /api/v1/cases/{id}/claims` | Return evidence refs and verification status |
| Save draft | `PATCH /api/v1/drafts/{id}` | Revision/hash conflict detection |
| Test prompt | `POST /api/v1/prompts/{id}/tests` | Sandboxed; no production side effects |
| Activate prompt | `POST /api/v1/prompts/{id}/activate` | Requires permission, confirmation, audit |
| Add custom provider | `POST /api/v1/integrations/ai-providers` | Draft config; no secret in response |
| Store provider secret | `POST /api/v1/integrations/ai-providers/{id}/credentials` | Secret manager; never echo value |
| Test provider | `POST /api/v1/integrations/ai-providers/{id}/test` | Safe test call; report capabilities |
| Connect CMS | `POST /api/v1/integrations/cms-connections` | Draft state; no test post by default |
| Editorial decision | `POST /api/v1/cases/{id}/approvals` | Exact revision/draft hash |
| Queue publish | `POST /api/v1/cases/{id}/publish-jobs` | Backend rechecks approval/permission |
| Reconcile result | `POST /api/v1/publish-jobs/{id}/reconcile` | Lookup external status before retry |
| Live progress | `GET /api/v1/events/stream` | Authenticated SSE; redact sensitive payload |

## Shared error handling
Error shape: `{ error: { code, message, details, request_id, retryable } }`.
Show safe human-readable messages and request ID. Do not show stack traces, secret values, raw provider bodies, or internal prompts.
