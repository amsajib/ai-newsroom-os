# Deployment Runbook (Draft)

## Environments
- `local`: mock providers and local/test CMS only.
- `development`: isolated Neon branch, sandbox credentials.
- `staging`: production-like config with test CMS site and capped provider spend.
- `production`: explicit approval and monitored rollout.

## Secrets/config
- `DATABASE_URL`: pooled connection for normal app queries.
- `DATABASE_URL_UNPOOLED`: direct connection for migration tools.
- Provider and CMS credentials: secret-manager references injected server-side.
- Never prefix secrets with client-exposed environment variable prefixes.
- Validate required environment variables at process startup; fail closed when a critical secret is missing.

## Release procedure
1. Review diff, migration, and security-sensitive changes.
2. Apply migration to a disposable Neon branch and run tests.
3. Deploy API and worker to staging.
4. Run contract/integration/E2E tests against sandbox provider and designated CMS test site.
5. Confirm approval gate and unknown-result reconciliation behavior.
6. Take/verify recovery point as supported by plan and policy.
7. Deploy gradually; monitor error rates, queue backlog, spend, and CMS job outcomes.
8. Keep rollback package and compatible database migration strategy ready.
9. Do not enable production publishing until an editor has approved a test workflow and all gates pass.

## Incident: provider credential compromise
1. Disable integration to stop new calls.
2. Revoke/rotate credential in provider and secret manager.
3. Review audit and request logs for exposure/use.
4. Re-test connection and capability set.
5. Re-enable only after authorization and incident review.

## Incident: uncertain or duplicate publication
1. Freeze automatic retries for affected publish job.
2. Look up external post by returned ID or supported correlation marker.
3. Update local state only after confirmed external status.
4. Escalate ambiguous duplicate risk to editor/admin; do not fabricate success.
