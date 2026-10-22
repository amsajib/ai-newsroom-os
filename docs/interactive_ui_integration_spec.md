# AI Newsroom OS — Interactive UI Integration Spec v1

## Implementation status
This is the UI implementation contract. It does not mean a live UI has been wired to the backend. Existing prototype work was described as demo-data only; the integration layer below is still required.

## Stack requirements
- Next.js + TypeScript.
- Tailwind CSS and shadcn/ui.
- Shared shadcn components in `components/ui/`.
- Feature components grouped under `components/newsroom/`.
- API calls only through typed client functions; do not call providers/CMS directly from the browser.
- Server-side authorization is authoritative; UI route guards are only user experience.

## Route map
- `/dashboard` — operational overview, queue health, runs, review backlog.
- `/news-desk` — cases list, filters, create case.
- `/news-desk/new` — intake form, source notes, image upload.
- `/news-desk/[caseId]` — workspace with overview, sources, claims, draft, media, SEO, CMS, history.
- `/agents` — eight agents, enable/disable, capability and status.
- `/agents/[agentKey]/prompt` — prompt editor with draft/test/activate/history/rollback.
- `/models` — built-in/custom provider setup, model catalog, capability tests, routing priority.
- `/integrations` — sources, media processing, CMS connections, health status.
- `/review-queue` — exact-revision editorial review and approval.
- `/publish-jobs` — publish state, external result, reconciliation-required items.
- `/audit` — searchable audit timeline (permission-gated).
- `/settings/security` — users, roles, secret status, retention and policy controls (admin-only).

## Component layout
```text
app/
  (workspace)/
    dashboard/page.tsx
    news-desk/page.tsx
    news-desk/new/page.tsx
    news-desk/[caseId]/page.tsx
    agents/page.tsx
    agents/[agentKey]/prompt/page.tsx
    models/page.tsx
    integrations/page.tsx
    review-queue/page.tsx
    publish-jobs/page.tsx
    audit/page.tsx
components/
  ui/                         # shadcn primitives
  newsroom/
    app-sidebar.tsx
    topbar.tsx
    status-badge.tsx
    case-table.tsx
    case-intake-form.tsx
    source-panel.tsx
    claims-evidence-table.tsx
    draft-editor.tsx
    media-studio.tsx
    prompt-editor.tsx
    prompt-test-panel.tsx
    model-provider-form.tsx
    capability-matrix.tsx
    integration-health-card.tsx
    editorial-approval-panel.tsx
    publish-job-timeline.tsx
    audit-timeline.tsx
lib/
  api-client.ts
  schemas/
  permissions.ts
  query-keys.ts
  event-stream.ts
```

## Screen requirements

### Dashboard
- Queue counts by state; recent run failures; review-required cases; integration health; cost/usage only from recorded provider reports/estimates.
- Every count links to a filtered view.
- Never label a case "published" unless confirmed by CMS response.

### News Desk
- Search/filter by status, date, language, assigned editor, sensitivity flags.
- Intake fields: title, context, source URLs/notes, language, sensitivity indicators, raw media uploads.
- Autosave must show save state and use optimistic concurrency/version check.
- Case revisions and original uploads remain visible in history.

### Case workspace
Tabs: Overview, Sources, Claims & Evidence, Draft, Media, SEO, CMS Preview, Activity.
- Claim rows show exact claim, status, supporting/contradicting evidence, source reliability, and reason.
- Draft editor highlights paragraphs tied to claims; unverified/contradicted content is visibly flagged.
- Material edits after approval visibly reset approval state.
- CMS Preview renders sanitized content and mapped fields without publishing.

### Prompt Editor
- Prompt version list; immutable published versions.
- Draft -> Test -> Activate flow.
- Test input/output, schema validation, policy assertions, provider/model, and cost/latency when known.
- Rollback activates a prior immutable version; it does not edit the historical text.
- Confirm before activation; show who activated and when.

### Models and integrations
- Provider forms support built-in and custom endpoint configurations.
- Secret entry uses one-time secure submit; subsequent UI displays only configured/missing/invalid.
- Per-model capability matrix; unsupported capability blocks incompatible agent configuration.
- Health check never creates content or triggers a production publish.
- CMS mapping supports test/preview; production publishing remains gated by approval.

### Review queue
- Show exact revision and draft hash, evidence/claim status, sensitivity flags, media lineage, SEO and CMS preview.
- Reviewer can approve, reject, or request changes with notes.
- Approval action names the exact revision/hash.
- Publish button appears only when policy and permission checks pass; backend repeats all checks.

### Publishing
- Display queued/running/succeeded/failed/unknown-needs-reconciliation.
- Show actual CMS post ID, URL and response timestamp only if returned/confirmed.
- Uncertain result offers reconciliation, not blind retry.
- No fabricated success toast.

## API and state management
- Typed API client with shared error envelope and request ID.
- Query/cache invalidation after mutations.
- Server-Sent Events for workflow progress; reconnect with backoff and replay cursor if supported.
- Use schema validation for API responses and forms.
- Mutations carry idempotency keys where required.
- Use optimistic updates only for reversible UI-only state; not for approval/publishing outcomes.

## Accessibility and responsiveness
- Keyboard accessible controls, visible focus, semantic labels, error summaries.
- Layout works on mobile and desktop; dense evidence tables switch to stacked cards on small screens.
- Color is not the only status indicator; pair labels/icons with status.
- Reduced-motion support.
