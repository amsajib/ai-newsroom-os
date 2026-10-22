# Phase 1 Foundation Decisions

## Status
Draft implementation artifacts only. The SQL has not been applied to Neon; no site, provider, or CMS has been connected.

## Architecture
- Frontend: Next.js + TypeScript + shadcn/ui + Tailwind.
- API: modular backend with separate background worker.
- System of record: Neon PostgreSQL.
- Migration authority: Drizzle Kit only; do not mix schema migration tools.
- Normal application queries use Neon pooled connection; migrations use direct/unpooled connection.
- Binary media goes to S3-compatible object storage; PostgreSQL stores metadata, checksums, and references.
- Model providers, source retrieval, media processing, and CMS are adapters behind normalized interfaces.

## Non-negotiable rules
1. Agent completion does not mean a claim is true, an editor approved it, or content was published.
2. Every run snapshots prompt version/hash, provider/model identity, input hash, and output references.
3. Approval is bound to an exact draft/revision hash; any content change requires re-approval.
4. Publishing checks permission, policy gates, latest approval, and hash immediately before external write.
5. An uncertain CMS outcome becomes `unknown_needs_reconciliation`; reconcile before retry.
6. Persist secret-manager references only, never raw keys/passwords/tokens in DB or logs.
7. Original media is immutable; derivatives preserve lineage, transformation details, and provenance.
8. Source fetchers must block SSRF targets, private/loopback/link-local/metadata addresses, unsafe redirects, and oversized responses.
9. Submitted text is untrusted data, not instructions for agents.
10. Sensitive claims require human review according to policy.

## Workflow states
`draft -> queued -> running -> review_required -> approved -> publishing -> published`
Exception/terminal states: `publish_failed`, `blocked`, `cancelled`. `published` requires an actual confirmed CMS result. Content changes invalidate approval. Do not represent uncertain publication as success.

Task states: `pending -> queued -> running -> completed|failed|blocked|cancelled`; dependencies are checked server-side. Retries are bounded and idempotent.

## RBAC minimum
- Admin: manage users, integrations, credentials, and configuration.
- Editor: edit/review, approve exact revision, and publish only if separately granted publish permission.
- Reporter: create/edit cases and start workflows; cannot approve/publish.
- Media editor: media-scoped changes and review.
- Viewer: read-only access to permitted resources.
Enforce authorization in backend services/routes, not just UI visibility.

## API conventions
- Base path `/api/v1`; JSON; UUIDs; UTC timestamps.
- Error envelope: `error.code`, `message`, `details`, `request_id`, `retryable`.
- Idempotency keys for workflow creation, retries, and CMS writes.
- SSE for authorized live workflow updates.
- Signed upload URLs or authenticated multipart; validate size, MIME, decoded file type, checksum, and quarantine state.
- Generate and validate OpenAPI 3.1 in CI.

## Important schema review items before production
- Decide workspace/organization tenancy before applying row-level security.
- Add service/database enforcement for prompt immutability, original-media immutability, audit append-only policy, and approval invalidation.
- Add cycle detection for task dependencies in workflow service.
- Add explicit unique indexes for nullable provider-level capabilities if needed.
- Review all indexes and FK deletion policies against retention/legal requirements.
- Apply only to a disposable Neon branch first, then test lifecycle before staging/production.
