# AI Newsroom OS — External Integration Contracts v1.2

## Status
Implementation contract draft. These adapters are specified, not connected. No provider, source API, media processor, or CMS has been tested against a live account in this work.

## 1. Integration registry model
Every integration instance has:
- `integration_instance_id`
- `integration_type`: `ai_provider | source | media | cms`
- `adapter_key`
- `display_name`
- `base_url` (where applicable)
- `status`: `draft | active | disabled | error`
- `config` (non-secret settings only)
- `credential_secret_ref` (secret manager reference only)
- `capabilities`
- `last_health_check`
- `created_by`, timestamps, and audit history

Never store raw API keys, Application Passwords, OAuth access tokens, or custom auth header values in the normal database, application logs, audit payloads, or UI responses.

## 2. Normalized AI model contract

```ts
type ProtocolFamily = "openai-compatible" | "anthropic-compatible" | "custom";

interface ModelCapabilities {
  textGeneration: boolean;
  vision: boolean;
  structuredOutput: boolean;
  toolCalling: boolean;
  streaming: boolean;
  usageReporting: boolean;
}

interface NormalizedModelRequest {
  modelId: string;
  systemInstructions: string;
  messages: Array<{ role: "user" | "assistant"; content: string | Array<unknown> }>;
  temperature?: number;
  maxOutputTokens?: number;
  responseFormat?: "text" | "json";
  tools?: Array<unknown>;
  stream?: boolean;
  timeoutMs: number;
  trace: { caseId: string; taskId: string; runId: string; requestId: string };
}

interface NormalizedModelResponse {
  modelId: string;
  outputText: string;
  structuredOutput?: unknown;
  finishReason?: string;
  usage?: { inputTokens?: number; outputTokens?: number; providerReported: boolean };
  providerRequestId?: string;
  latencyMs: number;
}

interface ModelAdapter {
  validateConfiguration(config: ProviderConfig): Promise<void>;
  getCapabilities(config: ProviderConfig, modelId: string): Promise<ModelCapabilities>;
  generate(config: ProviderConfig, request: NormalizedModelRequest): Promise<NormalizedModelResponse>;
  healthCheck(config: ProviderConfig): Promise<IntegrationHealth>;
}
```

Provider families:
- Built-in adapters may support OpenAI, Google Gemini, Anthropic, and OpenRouter, subject to implementation and provider policy.
- Custom endpoint can use OpenAI-compatible, Anthropic-compatible, or a dedicated `custom-adapter`.
- A protocol label is not proof of capability. Test every registered model for structured output, vision, tool calling, streaming, and usage reporting independently.
- Model discovery is optional. If unavailable or unreliable, permit manual model ID entry and a connection/capability test.
- Never silently switch provider/model. Any fallback must be allowed by policy, recorded in run metadata, and pass the same output/policy validation.

## 3. Provider configuration API
- `POST /api/v1/integrations/ai-providers` — create provider instance in draft state.
- `GET /api/v1/integrations/ai-providers` — list only authorized instances; never return secret values.
- `GET /api/v1/integrations/ai-providers/{id}` — get configuration and safe credential status.
- `PATCH /api/v1/integrations/ai-providers/{id}` — update non-secret settings; audit changes.
- `POST /api/v1/integrations/ai-providers/{id}/credentials` — store/rotate secret through secret manager.
- `POST /api/v1/integrations/ai-providers/{id}/test` — test auth, protocol and selected model.
- `POST /api/v1/integrations/ai-providers/{id}/models/discover` — optional model discovery.
- `POST /api/v1/integrations/ai-providers/{id}/models` — register a model manually.
- `GET /api/v1/integrations/ai-providers/{id}/models` — list models and verified capabilities.
- `PATCH /api/v1/integrations/ai-providers/{id}/models/{modelId}` — update safe metadata/capability overrides with audit.
- `POST /api/v1/integrations/ai-providers/{id}/disable` — block new runs; retain run history.

Connection test response:
```json
{
  "connection_status": "success | failed | partial",
  "protocol_validation": "passed | failed | not_applicable",
  "model_id": "provider-model-id",
  "capabilities": {
    "textGeneration": true,
    "vision": false,
    "structuredOutput": true,
    "toolCalling": false,
    "streaming": true,
    "usageReporting": true
  },
  "tested_at": "server-generated timestamp",
  "safe_message": "No secret values or raw provider response included"
}
```

## 4. Source retrieval contract
```ts
interface NormalizedSourceDocument {
  sourceId: string;
  url?: string;
  canonicalUrl?: string;
  title?: string;
  publisher?: string;
  author?: string;
  publishedAt?: string;
  retrievedAt: string;
  bodyText: string;
  contentHash: string;
  extractionWarnings: string[];
  metadata: Record<string, unknown>;
}

interface SourceAdapter {
  getCapabilities(): Promise<{ search: boolean; fetchUrl: boolean; rss: boolean; officialApi: boolean }>;
  search(request: { query: string; language?: string; limit: number }): Promise<NormalizedSourceDocument[]>;
  fetch(request: { url: string }): Promise<NormalizedSourceDocument>;
  healthCheck(): Promise<IntegrationHealth>;
}
```
- Supported source classes: user-supplied URLs, RSS/Atom feeds, official public APIs, and manual uploads.
- Search APIs are optional adapters, not assumed to be available.
- Preserve source URL, canonical URL when known, publisher, retrieval timestamp, content hash, extraction warnings, and excerpts used as evidence.
- Retrieved content is untrusted input. It cannot modify system prompts, trigger arbitrary tools, or override editorial rules.
- A source is not automatically trustworthy because it is accessible. Keep source reliability assessment separate from the claim's verification state.

## 5. Media processing contract
- Keep originals immutable and checksum-verified.
- Derivative metadata must include source asset ID, transformations, tool/agent, creation timestamp, checksum, dimensions, MIME type, and provenance.
- Deterministic operations: crop, resize, compression, safe color/exposure adjustments, format conversion, thumbnail layout.
- AI-assisted enhancement must be explicitly labeled and policy-checked; do not invent or remove material documentary details in news evidence.
- Do not permit face replacement, object insertion/removal, fabricated scene detail, or misleading manipulation of documentary images.
- Every upload checks file size, decoded type, dimensions, checksum, and quarantine/malware status.

## 6. Canonical CMS content payload
```ts
interface CanonicalCMSContent {
  caseId: string;
  revisionId: string;
  draftId: string;
  contentHash: string;
  headline: string;
  subheadline?: string;
  slug?: string;
  bodyHtml: string;
  excerpt?: string;
  language: string;
  categoryIds?: string[];
  tags?: string[];
  featuredMediaAssetId?: string;
  seoTitle?: string;
  seoDescription?: string;
  altText?: string;
  editorialApprovalId: string;
  approvedHash: string;
}
```
The CMS adapter must not decide whether content is editorially approved. Backend policy gate validates the approval and hash immediately before the adapter is called.

## 7. CMS adapter contract
```ts
interface CMSOperationResult {
  outcome: "draft_created" | "published" | "failed" | "unknown";
  externalContentId?: string;
  canonicalUrl?: string;
  externalStatus?: string;
  safeMessage?: string;
  responseMetadataRedacted: Record<string, unknown>;
}

interface CMSAdapter {
  getCapabilities(): Promise<{ createDraft: boolean; publish: boolean; uploadMedia: boolean; categories: boolean; tags: boolean; statusLookup: boolean }>;
  validateContent(content: CanonicalCMSContent): Promise<{ valid: boolean; issues: string[] }>;
  createDraft(content: CanonicalCMSContent, idempotencyKey: string): Promise<CMSOperationResult>;
  publish(content: CanonicalCMSContent, idempotencyKey: string): Promise<CMSOperationResult>;
  getPublicationStatus(externalContentId: string): Promise<CMSOperationResult>;
  healthCheck(): Promise<IntegrationHealth>;
}
```

## 8. WordPress REST API adapter
### Connection profiles
1. Self-hosted WordPress REST API: base URL such as `https://news.example.com/wp-json/wp/v2`.
2. WordPress.com site: use the supported WordPress.com API/authorization path for that site. Do not assume self-hosted Application Password authentication applies identically to every WordPress.com plan/site.
3. Custom reverse proxy: only if explicitly configured and verified by an administrator.

### Self-hosted authentication
- Preferred initial integration: dedicated WordPress service/editor account with least privilege and an Application Password over HTTPS.
- Application Password is stored in a secret manager, never in `cms_connections.config`.
- Test `/users/me` (or supported equivalent) before enabling write operations.
- If a plugin or host disables Application Passwords, stop and use an explicitly supported OAuth/plugin/API route; do not bypass security controls.
- Do not request the WordPress administrator's primary password.

### REST resources and mapping
- Posts: `POST /wp-json/wp/v2/posts` to create/update a post.
- Media: `POST /wp-json/wp/v2/media` to upload an image, using authenticated multipart upload.
- Categories: `/wp-json/wp/v2/categories`.
- Tags: `/wp-json/wp/v2/tags`.
- Current user/auth check: `/wp-json/wp/v2/users/me` when available to the credential's capabilities.
- SEO fields depend on installed SEO plugin and REST exposure. Do not assume Yoast/Rank Math/custom fields are writable unless the integration test confirms it.

Canonical mapping baseline:
- `headline` → `title`
- `bodyHtml` → `content`
- `excerpt` → `excerpt`
- `slug` → `slug`
- `categoryIds` → `categories`
- `tags` → `tags`
- `featuredMediaAssetId` → external WordPress media ID in `featured_media`
- Initial status → `draft`
- Approved publication status → `publish` only after backend approval/hash gate
- SEO metadata → plugin-specific exposed fields after capability discovery; otherwise omit and report unsupported.

### Safe connection lifecycle
1. Admin enters HTTPS site URL and chooses WordPress profile.
2. Backend normalizes base URL, rejects unsafe URL/redirects and private network targets unless explicitly allowlisted for an administrator-managed self-hosted environment.
3. Credential is stored via secret manager; UI only sees `configured / missing / invalid`, never the value.
4. Test authentication and minimal capabilities; do not create a post during connection test.
5. Fetch supported post/media/taxonomy features and field mappings.
6. Save mapping as draft; admin reviews and activates it.
7. Create a test draft only on explicit request, mark it clearly as a test, and record the returned post ID/edit URL.
8. Production workflow creates a draft first. Publishing requires approval for the exact draft hash and a separate publish permission.
9. After write, confirm by response and status lookup. On timeout, mark `unknown_needs_reconciliation`; query external status before retry.

### Idempotency and duplicate prevention
WordPress REST API does not universally guarantee arbitrary idempotency keys. Store a local publish job key, use a stable correlation marker where safe and supported, and reconcile by external post ID/status before retries. Never claim exactly-once delivery unless the target adapter provides that guarantee.

### WordPress-specific caveats
- Custom post types, SEO fields, media metadata, and custom taxonomies vary by site/plugin.
- The account's capabilities determine whether draft creation or publishing is allowed.
- Do not switch directly to `publish` merely because the AI workflow completed.
- Do not store admin cookies or browser session tokens as an integration credential.
- Never infer a publication URL; use the URL returned by WordPress or a confirmed follow-up fetch.

## 9. Failure and retry policy
- Authentication/permission error: no automatic retry; mark configuration/actionable error.
- Rate limit/temporary server error: bounded exponential backoff with jitter, respecting `Retry-After`.
- Schema/content validation error: return field-level errors; at most one controlled correction cycle if safe.
- Timeout with uncertain side effect: reconcile first; never blindly retry CMS writes.
- Provider fallback: only if policy allows; log original and selected provider/model; re-run validation.
- Disabled integration: no new calls; existing run history remains accessible.

## 10. SSRF and credential security
- Require HTTPS outside explicit local development.
- Resolve and validate DNS and every redirect hop; block loopback, private, link-local, IPv6 local, multicast, and cloud metadata endpoints by default.
- For a self-hosted CMS on a private network, require explicit administrator allowlist and narrowly scoped egress permission.
- Limit response bytes, connection/read timeout, redirect count, MIME types, and decompression ratio.
- Redact authorization headers, cookies, keys, passwords, provider prompts that contain secrets, and sensitive response bodies from logs.
- Audit integration creation, credential rotation/revocation, mapping changes, test outcomes, activation, and disable events.
