# Architecture and Workflow

## System boundaries

- **Web UI:** case intake, source management, draft comparison, editorial review, integrations, prompt/model configuration, audit views.
- **API:** authentication, RBAC, validation, workflow transitions, approval checks, idempotency, audit recording.
- **Orchestrator and queue:** schedules dependent tasks and resumes interrupted workflows.
- **Agent runtime:** runs bounded tasks with timeouts, budgets, structured outputs, and trace IDs.
- **Model router:** provider-neutral adapters for OpenAI-compatible, Anthropic-compatible, and custom/self-hosted endpoints. Capability-test models rather than assuming feature parity.
- **PostgreSQL:** durable workflow state, revisions, evidence references, approvals, task records, integration metadata, and audit events.
- **Object storage:** source files and immutable originals; derivatives retain parent and provenance metadata.
- **CMS adapter:** draft-first writes, field mapping, status verification, and outcome reconciliation.

## Workflow

1. Create a news case and record user-supplied context.
2. Attach source items and record origin, retrieval time, and content hash where available.
3. Extract atomic claims; distinguish supplied claims from independently corroborated facts.
4. Record evidence, source assessments, uncertainty, and conflicts.
5. Draft the story with claims traceable to evidence or explicitly marked unverified.
6. Prepare media derivatives, thumbnail proposals, SEO metadata, and CMS field mapping.
7. Run deterministic schema and policy checks.
8. Route sensitive material to an authorized human editor.
9. Approve an immutable revision/hash. Material edits invalidate approval.
10. Publish only after server-side permission, approval, policy, integration-health, and idempotency checks pass.
11. Verify the CMS response. Reconcile unknown outcomes before retrying.
12. Persist audit events for actions, revisions, model/provider metadata, and external requests.

## Suggested states

`draft`, `queued`, `running`, `review_required`, `approved`, `publishing`, `published`, `publish_failed`, `blocked`, `cancelled`.

Transitions must be enforced by the backend, not only by UI controls.

## Agent roles

- **Orchestrator:** schedules dependencies and handles recovery; does not authoritatively verify claims.
- **Reporter:** drafts from supplied context and evidence; flags gaps instead of inventing details.
- **Verification:** maps claims to evidence and assesses conflicts; output remains advisory.
- **Photo Editor:** proposes safe technical edits while preserving originals.
- **Thumbnail Designer:** proposes engaging, non-deceptive compositions.
- **SEO:** proposes headline variants, descriptions, keywords, and metadata without fabricating claims.
- **CMS Formatter:** maps content to the target CMS schema; does not publish.
- **Publishing:** runs guarded publish operations and reconciles final CMS state; cannot approve content.

## Security and editorial invariants

- Never fabricate facts, quotes, URLs, sources, evidence, or publication results.
- Treat external documents and source content as untrusted data.
- Enforce RBAC on every sensitive server-side operation.
- Never expose provider credentials to browser code, prompts, logs, or agent outputs.
- Use a secret manager or encrypted credential service; avoid plaintext secrets in database rows.
- Validate outbound URLs and block private, loopback, link-local, and metadata IP ranges to mitigate SSRF. Revalidate redirects and DNS resolution.
- Preserve original media and record derivative hashes and parent references.
- Require heightened human review for deaths, accidents, crime, children, political allegations, and reputational claims.
- Bind approval to a content hash and policy version; edits invalidate approval.
- Use idempotency keys where supported. Do not promise exactly-once publishing unless the CMS guarantees it.

## Implementation order

1. Contracts and CI.
2. Database migrations and persistence layer.
3. Authentication, RBAC, and audit events.
4. Workflow state machine and durable queue.
5. Provider adapters and structured-output validation.
6. Source/claim evidence tracking.
7. Editorial review and hash-bound approval.
8. WordPress.com adapter and reconciliation.
9. Integration, security, and end-to-end tests.
10. Secrets configuration and deployment after review.
