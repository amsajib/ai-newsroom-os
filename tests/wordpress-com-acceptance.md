# WordPress.com adapter tests
- [ ] Token is server-side only and never returned/logged.
- [ ] Connection test does not create or modify posts.
- [ ] Invalid token and permission errors are safely normalized.
- [ ] Draft endpoint requires editor permission and explicit `confirmDraftCreation: true`.
- [ ] Adapter always sends `status=draft`; no publish route exists in this patch.
- [ ] External post ID/status/URL come only from WordPress response.
- [ ] Unknown write outcome is reconciled before retry.
- [ ] Audit metadata excludes credentials and raw provider responses.
- [ ] Publish service (added later) enforces exact content-hash approval.
