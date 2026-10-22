# Release Test Matrix

## Unit
- [ ] State transition rules reject invalid transitions.
- [ ] Approval hash comparison rejects changed content.
- [ ] Agent output schema and business-rule validation reject fabricated/missing refs.
- [ ] Idempotency service prevents duplicate local jobs.
- [ ] Secret redaction covers headers, query strings, exception text, and nested JSON.

## Integration
- [ ] Neon migration applies to clean branch and rollback/recovery procedure is documented.
- [ ] Database constraints and service-level permission checks both behave correctly.
- [ ] Model adapter normalizes success, timeout, rate limit, malformed response, and auth errors.
- [ ] CMS adapter creates draft and reads status in staging.
- [ ] Source adapter blocks SSRF and unsafe redirects.
- [ ] Media upload validates file bytes and stores immutable original.

## End-to-end
- [ ] Intake -> sources -> claims -> verification -> draft -> recheck -> human review -> approval -> CMS draft.
- [ ] Sensitive story cannot bypass human review.
- [ ] Contradicted claim blocks publish as written.
- [ ] Content edit after approval invalidates approval.
- [ ] Publishing requires separate permission and exact approved hash.
- [ ] CMS timeout after write reconciles before retry.
- [ ] Provider disable/failure prevents new runs or uses explicitly allowed fallback.

## Security
- [ ] Cross-user resource access denied.
- [ ] Privilege escalation attempts denied.
- [ ] Prompt injection in article/source cannot access tools or secrets.
- [ ] SSRF target and redirect suite passes.
- [ ] Oversized upload, MIME spoof, malformed media rejected.
- [ ] Secret scan of logs, traces, DB fixtures, and API responses passes.
- [ ] Rate limiting and cost ceilings stop abuse.

## Operational
- [ ] Metrics and alerts tested with injected failures.
- [ ] Stuck task and dead-letter recovery exercised.
- [ ] Backup restore drill completed.
- [ ] Rollback plan reviewed.
- [ ] Staging test post removed only after external ID is confirmed and deletion is authorized.
