# Phase 1 Acceptance Tests

## Migration
- [ ] Apply to a disposable Neon branch with direct/unpooled connection.
- [ ] Validate schema, foreign keys, unique constraints, enum values, indexes, and seeds.
- [ ] Re-run migration through migration tool version tracking without drift.
- [ ] Confirm no raw credentials exist in database or logs.

## Case/revision
- [ ] Create case and initial revision; current revision must belong to that case.
- [ ] New revisions preserve prior revisions and increment revision number.
- [ ] Duplicate revision numbers and invalid required fields are rejected.
- [ ] Stale updates return conflict instead of overwriting newer content.

## Agents/workflow
- [ ] Exactly one active prompt per agent.
- [ ] Prompt versions are immutable; rollback reactivates a historical version without rewriting it.
- [ ] Runs retain prompt hash and provider/model identity after settings change.
- [ ] Unmet dependencies prevent task execution; service rejects dependency cycles.
- [ ] Retries are bounded; cancellation is idempotent.

## Verification/editorial
- [ ] Claims without evidence remain UNVERIFIED.
- [ ] CONTRADICTED claims block publication as written.
- [ ] Sensitive claims require human review.
- [ ] Approval records bind to exact content hash; edits invalidate prior approval.

## CMS
- [ ] Publish without approval fails.
- [ ] Approval for another revision/hash fails.
- [ ] Duplicate idempotency key cannot create a second post.
- [ ] Uncertain timeout becomes reconciliation-required before retry.
- [ ] Published state requires confirmed external response and returned URL/ID.

## Security/API
- [ ] Unauthorized users cannot read/write resources outside their permissions.
- [ ] SSRF blocks loopback, private, link-local, IPv6-local, metadata endpoints, and unsafe redirects.
- [ ] Audit events cover prompt activation, credential changes, approval, and publishing.
- [ ] Uploads validate size, decoded file type, checksum, and quarantine status.
- [ ] OpenAPI validates in CI and matches implemented routes.
