# Standard News Workflow v1

## Dependency plan
1. Intake & schema validation
2. Source collection and claim extraction
3. Claim verification
4. Reporter draft (only supported/qualified claims)
5. Verification recheck against exact draft
6. Media derivative generation and thumbnail design (can run in parallel after assets/intake)
7. SEO generation (after draft and verification recheck)
8. CMS formatting and content sanitization
9. Backend policy validation + human editorial review
10. Approval recorded against exact draft/revision hash
11. Publish job preflight and CMS operation
12. Confirm external result; reconcile uncertain outcomes
13. Save final audit record and actual canonical URL

## Task creation rules
- Backend validates agent keys, dependencies, allowed transitions, and policy.
- Reject dependency cycles before enqueueing.
- Store input refs, prompt version/hash, provider/model identity, idempotency key, and output artifact refs.
- Do not allow an agent to change workflow status directly.
- Agent output is untrusted until schema, policy, and reference validation pass.

## Human review gates
Always require human review for sensitive content categories and policy-triggered uncertainty. Human approval is tied to a content hash, not just a case ID. Any material edit after approval requires new approval.

## Retry policy
- Auth/permission/configuration errors: no retry until corrected.
- Timeout/rate limit/transient 5xx: bounded retry with backoff and jitter.
- Invalid output schema: at most one constrained repair attempt, then fail/route to human.
- Contradicted claim: block affected wording; do not retry the same prompt blindly.
- CMS timeout after possible write: mark unknown and reconcile before retry.
