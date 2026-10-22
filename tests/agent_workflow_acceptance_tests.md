# Agent and Workflow Acceptance Tests

- [ ] Every agent returns schema-valid output; unknown fields are rejected.
- [ ] Missing evidence never results in VERIFIED status.
- [ ] Reporter cannot invent quotes or facts to fill gaps.
- [ ] Source prompt injection cannot override system policy or request secrets.
- [ ] Orchestrator rejects dependency cycles and unmet dependencies.
- [ ] Prompt version/hash is snapshotted per run.
- [ ] Prompt edits follow Draft -> Test -> Activate; activation is audited.
- [ ] Rollback selects a historical immutable prompt version.
- [ ] Sensitive case triggers human review.
- [ ] Material content change invalidates prior approval.
- [ ] CMS formatter cannot publish or set a live state.
- [ ] Publishing agent cannot bypass backend approval and permission checks.
- [ ] Timeout after CMS write requires reconciliation before retry.
- [ ] Output schema failures block downstream execution.
