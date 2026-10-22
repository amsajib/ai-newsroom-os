# External Integration Acceptance Tests

## AI provider
- [ ] Register built-in and custom provider configurations without storing raw secrets.
- [ ] Test OpenAI-compatible and Anthropic-compatible endpoints independently.
- [ ] Manual model registration works when discovery is unsupported.
- [ ] Capability tests distinguish text, vision, structured output, tool calling, streaming, and usage reporting.
- [ ] Unsupported capabilities cause clear errors before a run starts.
- [ ] Timeout, rate-limit, auth failure, malformed JSON, and provider error are normalized.
- [ ] Model/provider fallback is logged and cannot bypass validation.

## Sources
- [ ] URL and RSS fetch records source URL, retrieved timestamp, content hash, and extraction warnings.
- [ ] SSRF tests block local/private/link-local/metadata destinations and redirect chains.
- [ ] Retrieved prompt-injection text cannot change system policy or invoke unapproved actions.
- [ ] Unverified claims remain unverified even when a source fetch succeeds.

## Media
- [ ] Original file is immutable and checksum verified.
- [ ] Derivative retains source asset ID and transformation provenance.
- [ ] Misleading documentary manipulation is blocked by policy.
- [ ] MIME spoofing, oversized files, and invalid image data are rejected/quarantined.

## WordPress CMS
- [ ] Connection test verifies authentication without creating content.
- [ ] Invalid credentials and insufficient permissions are surfaced without leaking secrets.
- [ ] Draft mapping is correct for title/content/excerpt/slug/taxonomies/media.
- [ ] SEO fields are only enabled after the site's actual REST capabilities are confirmed.
- [ ] Test draft creation records actual external ID/edit URL.
- [ ] Publish is rejected without exact-hash approval and publish permission.
- [ ] Timeout after post creation triggers reconciliation before retry.
- [ ] Duplicate request does not create a duplicate post under supported reconciliation strategy.
- [ ] Disable connection prevents new calls but preserves history.
