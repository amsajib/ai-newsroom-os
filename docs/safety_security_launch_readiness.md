# AI Newsroom OS — Safety, Security & Launch Readiness v1

## Status
Readiness specification only. No penetration test, provider test, deployment, backup restore, or live publishing test has been performed.

## Threat model and controls

### Identity and authorization
- Enforce RBAC in API and service layers for every read/write operation.
- Use short-lived sessions/tokens, secure cookie settings where applicable, CSRF protection for cookie-authenticated mutations, rate limits, and login abuse protection.
- Admin-only actions: provider/CMS configuration, credential rotation, user/role changes, prompt activation, policy changes.
- Approval and publish permissions must be distinct where newsroom policy requires it.
- Log access denials without leaking sensitive resource data.

### Secrets
- Use a managed secret store or encrypted secret service.
- Store only secret references in PostgreSQL.
- Redact Authorization headers, cookies, API keys, passwords, and secret-bearing URLs from logs/errors/traces.
- Rotate and revoke credentials; disabled integrations must not be used for new requests.
- Never ask users to paste credentials into chat or tickets.

### Source fetching / SSRF
- Permit only HTTP(S) URLs, preferably HTTPS.
- Resolve DNS and validate every redirect destination.
- Block loopback, RFC1918 private ranges, link-local, IPv6 local, multicast, and cloud metadata addresses by default.
- Permit private self-hosted endpoints only with explicit admin allowlist and network egress controls.
- Limit redirects, connect/read timeouts, response size, content types, and decompression ratio.
- Reject URL user-info credentials and suspicious encoded hosts.

### AI safety and data integrity
- Source content is untrusted; resist prompt injection and tool misuse.
- Backend validates agent outputs against JSON Schema and business rules.
- Do not trust agent-provided IDs, timestamps, hashes, approval states, or publication claims.
- Keep claim status and evidence provenance separate from prose generation.
- Sensitive claims require human review.
- Preserve original media; block deceptive alteration of documentary evidence.
- Human approval binds to exact content hash and is invalidated by material changes.

### CMS and external side effects
- CMS writes only through backend adapters.
- Draft first; publishing requires exact-hash approval, permission, policy pass, active integration, and idempotency key.
- Timeout with uncertain result requires reconciliation before retry.
- Record external IDs/URLs only when returned/confirmed.
- Avoid promising exactly-once semantics unless the target API guarantees it.

### Audit and privacy
- Audit prompt changes, model/provider changes, credentials, user permissions, editorial decisions, and CMS writes.
- Audit records are append-only by application policy; restrict read access.
- Minimize personal data and redact sensitive payloads.
- Define retention, deletion, export, and legal hold policies before production.
- Never put raw full prompts/source bodies into audit logs unless specifically required and protected.

## Production gates
1. Migration passes on disposable Neon branch.
2. API contract and generated OpenAPI pass CI validation.
3. Unit, integration, contract, security, and end-to-end tests pass.
4. Authentication, RBAC, CSRF, rate limit, upload validation, and secret redaction reviewed.
5. Provider and CMS health tests pass in a staging environment.
6. Staging workflow ends in draft/review; publishing is tested only with an explicitly designated test site.
7. Backup/restore and migration rollback plan is exercised.
8. Monitoring/alerts and on-call owner are assigned.
9. Cost/rate limits and provider fallback policies are configured.
10. User/editor training and incident-response runbook are ready.

## Observability
Capture request ID, case/workflow/task/run IDs, adapter key, model ID, latency, usage, safe error code, retry count, and state transitions. Do not log credentials or sensitive provider response bodies. Alert on repeated failures, rising costs, queue backlog, stuck tasks, publish reconciliation backlog, and integration health degradation.

## Recovery
- Idempotent task creation and retry.
- Dead-letter/failed-task queue with bounded re-drive.
- Stuck task sweeper and lease/heartbeat rules.
- CMS reconciliation worker for unknown outcomes.
- Database migration backups and branch-based testing.
- Object storage checksums and orphan asset cleanup with dry-run before deletion.
- Documented incident procedure for credential compromise and accidental publication.
