-- AI Newsroom OS Phase 1 initial migration draft (NOT applied to any database).
BEGIN;
CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TYPE case_status AS ENUM ('draft','queued','running','review_required','approved','publishing','published','publish_failed','blocked','cancelled');
CREATE TYPE task_status AS ENUM ('pending','queued','running','waiting_dependency','waiting_human','completed','failed','blocked','cancelled');
CREATE TYPE claim_status AS ENUM ('VERIFIED','PARTIALLY_VERIFIED','UNVERIFIED','CONTRADICTED');
CREATE TYPE integration_status AS ENUM ('draft','active','disabled','error');
CREATE TYPE publish_status AS ENUM ('queued','running','succeeded','failed','unknown_needs_reconciliation','cancelled');

CREATE TABLE users (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
 email text NOT NULL UNIQUE,
 display_name text NOT NULL,
 status text NOT NULL DEFAULT 'invited' CHECK (status IN ('active','invited','suspended','disabled')),
 created_at timestamptz NOT NULL DEFAULT now(),
 updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE roles (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
 role_key text NOT NULL UNIQUE,
 description text NOT NULL DEFAULT ''
);
CREATE TABLE user_roles (
 user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
 role_id uuid NOT NULL REFERENCES roles(id) ON DELETE RESTRICT,
 granted_by uuid REFERENCES users(id) ON DELETE SET NULL,
 granted_at timestamptz NOT NULL DEFAULT now(),
 PRIMARY KEY(user_id, role_id)
);
CREATE TABLE sessions (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
 user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
 session_hash text NOT NULL UNIQUE,
 expires_at timestamptz NOT NULL,
 revoked_at timestamptz,
 created_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE api_credentials (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
 owner_user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
 provider_key text NOT NULL,
 label text NOT NULL,
 secret_ref text NOT NULL,
 status text NOT NULL DEFAULT 'active' CHECK (status IN ('active','rotated','revoked')),
 metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
 created_at timestamptz NOT NULL DEFAULT now(),
 UNIQUE(owner_user_id, provider_key, label)
);
COMMENT ON COLUMN api_credentials.secret_ref IS 'Secret manager reference only; never store raw credentials.';

CREATE TABLE news_cases (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
 title text NOT NULL DEFAULT 'Untitled story',
 status case_status NOT NULL DEFAULT 'draft',
 language_code text NOT NULL DEFAULT 'bn',
 created_by uuid NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
 assigned_editor_id uuid REFERENCES users(id) ON DELETE SET NULL,
 current_revision_id uuid,
 sensitivity_flags text[] NOT NULL DEFAULT ARRAY[]::text[],
 metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
 created_at timestamptz NOT NULL DEFAULT now(),
 updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE case_revisions (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
 case_id uuid NOT NULL REFERENCES news_cases(id) ON DELETE CASCADE,
 revision_no integer NOT NULL CHECK (revision_no > 0),
 title text NOT NULL,
 submitted_context text NOT NULL DEFAULT '',
 source_notes text NOT NULL DEFAULT '',
 created_by uuid NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
 content_hash text,
 created_at timestamptz NOT NULL DEFAULT now(),
 UNIQUE(case_id, revision_no),
 UNIQUE(case_id, id)
);
ALTER TABLE news_cases ADD CONSTRAINT current_revision_belongs_to_case
 FOREIGN KEY (id, current_revision_id) REFERENCES case_revisions(case_id, id)
 DEFERRABLE INITIALLY DEFERRED;

CREATE TABLE source_items (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
 case_id uuid NOT NULL REFERENCES news_cases(id) ON DELETE CASCADE,
 revision_id uuid REFERENCES case_revisions(id) ON DELETE SET NULL,
 source_type text NOT NULL CHECK (source_type IN ('user_note','url','rss','official_api','document','image','manual')),
 source_url text,
 title text,
 publisher text,
 published_at timestamptz,
 retrieved_at timestamptz NOT NULL DEFAULT now(),
 storage_ref text,
 checksum_sha256 text,
 extracted_text text,
 metadata jsonb NOT NULL DEFAULT '{}'::jsonb
);
CREATE TABLE content_drafts (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
 case_id uuid NOT NULL REFERENCES news_cases(id) ON DELETE CASCADE,
 revision_id uuid NOT NULL REFERENCES case_revisions(id) ON DELETE RESTRICT,
 draft_no integer NOT NULL CHECK (draft_no > 0),
 headline text NOT NULL,
 subheadline text,
 body_markdown text NOT NULL DEFAULT '',
 excerpt text,
 language_code text NOT NULL DEFAULT 'bn',
 created_by_agent_key text NOT NULL,
 content_hash text NOT NULL,
 is_current boolean NOT NULL DEFAULT false,
 metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
 created_at timestamptz NOT NULL DEFAULT now(),
 UNIQUE(case_id, revision_id, draft_no)
);
CREATE UNIQUE INDEX one_current_draft_per_revision ON content_drafts(case_id, revision_id) WHERE is_current;
CREATE TABLE content_sections (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
 draft_id uuid NOT NULL REFERENCES content_drafts(id) ON DELETE CASCADE,
 ordinal integer NOT NULL CHECK (ordinal >= 0),
 section_type text NOT NULL,
 heading text,
 body text NOT NULL DEFAULT '',
 metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
 UNIQUE(draft_id, ordinal)
);
CREATE TABLE content_links (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
 draft_id uuid NOT NULL REFERENCES content_drafts(id) ON DELETE CASCADE,
 url text NOT NULL,
 anchor_text text,
 link_type text NOT NULL DEFAULT 'source',
 verified boolean NOT NULL DEFAULT false
);

CREATE TABLE agents (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
 agent_key text NOT NULL UNIQUE,
 display_name text NOT NULL,
 purpose text NOT NULL,
 enabled boolean NOT NULL DEFAULT true,
 configuration jsonb NOT NULL DEFAULT '{}'::jsonb,
 created_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE agent_prompt_versions (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
 agent_id uuid NOT NULL REFERENCES agents(id) ON DELETE RESTRICT,
 version_no integer NOT NULL CHECK (version_no > 0),
 prompt_text text NOT NULL,
 prompt_hash text NOT NULL,
 created_by uuid NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
 change_summary text NOT NULL DEFAULT '',
 is_active boolean NOT NULL DEFAULT false,
 created_at timestamptz NOT NULL DEFAULT now(),
 activated_at timestamptz,
 UNIQUE(agent_id, version_no),
 UNIQUE(agent_id, id)
);
CREATE UNIQUE INDEX one_active_prompt_per_agent ON agent_prompt_versions(agent_id) WHERE is_active;
CREATE TABLE prompt_test_runs (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
 prompt_version_id uuid NOT NULL REFERENCES agent_prompt_versions(id) ON DELETE RESTRICT,
 created_by uuid NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
 test_input jsonb NOT NULL,
 test_output jsonb,
 assertions jsonb NOT NULL DEFAULT '{}'::jsonb,
 passed boolean,
 created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE integration_definitions (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
 integration_key text NOT NULL UNIQUE,
 integration_type text NOT NULL CHECK (integration_type IN ('ai_provider','source','media','cms')),
 display_name text NOT NULL,
 adapter_key text NOT NULL,
 built_in boolean NOT NULL DEFAULT false
);
CREATE TABLE integration_instances (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
 definition_id uuid NOT NULL REFERENCES integration_definitions(id) ON DELETE RESTRICT,
 owner_user_id uuid REFERENCES users(id) ON DELETE CASCADE,
 display_name text NOT NULL,
 base_url text,
 protocol_family text,
 status integration_status NOT NULL DEFAULT 'draft',
 config jsonb NOT NULL DEFAULT '{}'::jsonb,
 created_at timestamptz NOT NULL DEFAULT now(),
 updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE integration_credentials (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
 integration_instance_id uuid NOT NULL REFERENCES integration_instances(id) ON DELETE CASCADE,
 credential_name text NOT NULL,
 secret_ref text NOT NULL,
 status text NOT NULL DEFAULT 'active' CHECK (status IN ('active','rotated','revoked')),
 created_at timestamptz NOT NULL DEFAULT now(),
 UNIQUE(integration_instance_id, credential_name)
);
COMMENT ON COLUMN integration_credentials.secret_ref IS 'Secret manager reference only; no plaintext API keys or passwords.';
CREATE TABLE integration_capabilities (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
 integration_instance_id uuid NOT NULL REFERENCES integration_instances(id) ON DELETE CASCADE,
 model_id text NOT NULL DEFAULT '',
 capability_key text NOT NULL,
 supported boolean NOT NULL,
 verification_status text NOT NULL CHECK (verification_status IN ('untested','tested_supported','tested_unsupported','admin_override')),
 tested_at timestamptz,
 evidence jsonb NOT NULL DEFAULT '{}'::jsonb,
 UNIQUE(integration_instance_id, model_id, capability_key)
);
CREATE TABLE integration_health_checks (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
 integration_instance_id uuid NOT NULL REFERENCES integration_instances(id) ON DELETE CASCADE,
 status text NOT NULL CHECK (status IN ('healthy','degraded','unavailable','configuration_error')),
 latency_ms integer CHECK (latency_ms IS NULL OR latency_ms >= 0),
 safe_message text,
 checked_at timestamptz NOT NULL DEFAULT now(),
 details_redacted jsonb NOT NULL DEFAULT '{}'::jsonb
);
CREATE TABLE provider_model_catalog (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
 integration_instance_id uuid NOT NULL REFERENCES integration_instances(id) ON DELETE CASCADE,
 model_id text NOT NULL,
 display_name text NOT NULL,
 context_window integer CHECK (context_window IS NULL OR context_window > 0),
 input_price_per_million numeric(14,6),
 output_price_per_million numeric(14,6),
 active boolean NOT NULL DEFAULT true,
 metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
 UNIQUE(integration_instance_id, model_id)
);
CREATE TABLE agent_model_configs (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
 agent_id uuid NOT NULL REFERENCES agents(id) ON DELETE CASCADE,
 integration_instance_id uuid NOT NULL REFERENCES integration_instances(id) ON DELETE RESTRICT,
 model_id text NOT NULL,
 priority integer NOT NULL DEFAULT 100,
 enabled boolean NOT NULL DEFAULT true,
 policy jsonb NOT NULL DEFAULT '{}'::jsonb,
 UNIQUE(agent_id, integration_instance_id, model_id)
);

CREATE TABLE workflow_definitions (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
 workflow_key text NOT NULL,
 version_no integer NOT NULL CHECK (version_no > 0),
 definition jsonb NOT NULL,
 active boolean NOT NULL DEFAULT false,
 created_at timestamptz NOT NULL DEFAULT now(),
 UNIQUE(workflow_key, version_no)
);
CREATE UNIQUE INDEX one_active_workflow_version ON workflow_definitions(workflow_key) WHERE active;
CREATE TABLE workflow_instances (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
 case_id uuid NOT NULL REFERENCES news_cases(id) ON DELETE CASCADE,
 case_revision_id uuid NOT NULL REFERENCES case_revisions(id) ON DELETE RESTRICT,
 workflow_definition_id uuid NOT NULL REFERENCES workflow_definitions(id) ON DELETE RESTRICT,
 status case_status NOT NULL DEFAULT 'queued',
 created_by uuid NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
 started_at timestamptz,
 completed_at timestamptz,
 metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
 created_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE agent_tasks (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
 workflow_instance_id uuid NOT NULL REFERENCES workflow_instances(id) ON DELETE CASCADE,
 task_key text NOT NULL,
 agent_id uuid NOT NULL REFERENCES agents(id) ON DELETE RESTRICT,
 status task_status NOT NULL DEFAULT 'pending',
 priority integer NOT NULL DEFAULT 100,
 attempt_count integer NOT NULL DEFAULT 0 CHECK (attempt_count >= 0),
 max_attempts integer NOT NULL DEFAULT 3 CHECK (max_attempts BETWEEN 0 AND 10),
 idempotency_key text NOT NULL UNIQUE,
 input_refs jsonb NOT NULL DEFAULT '[]'::jsonb,
 output_ref text,
 blocking_issues jsonb NOT NULL DEFAULT '[]'::jsonb,
 queued_at timestamptz,
 started_at timestamptz,
 completed_at timestamptz,
 created_at timestamptz NOT NULL DEFAULT now(),
 UNIQUE(workflow_instance_id, task_key)
);
CREATE TABLE task_dependencies (
 task_id uuid NOT NULL REFERENCES agent_tasks(id) ON DELETE CASCADE,
 depends_on_task_id uuid NOT NULL REFERENCES agent_tasks(id) ON DELETE CASCADE,
 dependency_type text NOT NULL DEFAULT 'success' CHECK (dependency_type IN ('success','completion','human_approval')),
 PRIMARY KEY(task_id, depends_on_task_id),
 CHECK(task_id <> depends_on_task_id)
);
CREATE TABLE agent_runs (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
 task_id uuid NOT NULL REFERENCES agent_tasks(id) ON DELETE CASCADE,
 attempt_no integer NOT NULL CHECK (attempt_no > 0),
 status text NOT NULL CHECK (status IN ('started','completed','failed','timed_out','cancelled')),
 prompt_version_id uuid REFERENCES agent_prompt_versions(id) ON DELETE RESTRICT,
 prompt_hash text,
 integration_instance_id uuid REFERENCES integration_instances(id) ON DELETE SET NULL,
 model_id text,
 input_hash text,
 started_at timestamptz NOT NULL DEFAULT now(),
 completed_at timestamptz,
 latency_ms integer CHECK (latency_ms IS NULL OR latency_ms >= 0),
 input_tokens integer CHECK (input_tokens IS NULL OR input_tokens >= 0),
 output_tokens integer CHECK (output_tokens IS NULL OR output_tokens >= 0),
 estimated_cost numeric(14,6),
 error_code text,
 safe_error_message text,
 UNIQUE(task_id, attempt_no)
);
CREATE TABLE run_artifacts (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
 run_id uuid NOT NULL REFERENCES agent_runs(id) ON DELETE CASCADE,
 artifact_type text NOT NULL,
 storage_ref text,
 content_json jsonb,
 checksum_sha256 text,
 metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
 created_at timestamptz NOT NULL DEFAULT now(),
 CHECK(storage_ref IS NOT NULL OR content_json IS NOT NULL)
);
CREATE TABLE handoff_records (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
 workflow_instance_id uuid NOT NULL REFERENCES workflow_instances(id) ON DELETE CASCADE,
 from_task_id uuid REFERENCES agent_tasks(id) ON DELETE SET NULL,
 to_task_id uuid NOT NULL REFERENCES agent_tasks(id) ON DELETE CASCADE,
 input_refs jsonb NOT NULL DEFAULT '[]'::jsonb,
 required_action text NOT NULL,
 blocking_issues jsonb NOT NULL DEFAULT '[]'::jsonb,
 idempotency_key text NOT NULL UNIQUE,
 status text NOT NULL CHECK (status IN ('pending','accepted','rejected','completed','failed')),
 created_at timestamptz NOT NULL DEFAULT now(),
 completed_at timestamptz
);
CREATE TABLE workflow_events (
 id bigserial PRIMARY KEY,
 workflow_instance_id uuid NOT NULL REFERENCES workflow_instances(id) ON DELETE CASCADE,
 task_id uuid REFERENCES agent_tasks(id) ON DELETE SET NULL,
 event_key text NOT NULL,
 payload_redacted jsonb NOT NULL DEFAULT '{}'::jsonb,
 created_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE run_usage (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
 run_id uuid NOT NULL REFERENCES agent_runs(id) ON DELETE CASCADE,
 usage_type text NOT NULL,
 quantity numeric(18,6) NOT NULL CHECK(quantity >= 0),
 unit text NOT NULL,
 cost numeric(14,6),
 provider_reported boolean NOT NULL DEFAULT false,
 metadata jsonb NOT NULL DEFAULT '{}'::jsonb
);

CREATE TABLE claims (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
 case_id uuid NOT NULL REFERENCES news_cases(id) ON DELETE CASCADE,
 revision_id uuid NOT NULL REFERENCES case_revisions(id) ON DELETE RESTRICT,
 claim_text text NOT NULL,
 classification text NOT NULL,
 verification_status claim_status NOT NULL DEFAULT 'UNVERIFIED',
 reason text NOT NULL DEFAULT '',
 source_reliability text NOT NULL DEFAULT 'unknown',
 source_url text,
 created_by_run_id uuid REFERENCES agent_runs(id) ON DELETE SET NULL,
 created_at timestamptz NOT NULL DEFAULT now(),
 updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE claim_evidence (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
 claim_id uuid NOT NULL REFERENCES claims(id) ON DELETE CASCADE,
 source_item_id uuid REFERENCES source_items(id) ON DELETE SET NULL,
 evidence_url text,
 evidence_excerpt text,
 evidence_type text NOT NULL DEFAULT 'supporting',
 assessment text NOT NULL DEFAULT '',
 captured_at timestamptz NOT NULL DEFAULT now(),
 metadata jsonb NOT NULL DEFAULT '{}'::jsonb
);
CREATE TABLE claim_verification_runs (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
 claim_id uuid NOT NULL REFERENCES claims(id) ON DELETE CASCADE,
 run_id uuid REFERENCES agent_runs(id) ON DELETE SET NULL,
 result claim_status NOT NULL,
 rationale text NOT NULL,
 checked_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE source_assessments (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
 source_item_id uuid NOT NULL REFERENCES source_items(id) ON DELETE CASCADE,
 assessment_type text NOT NULL,
 score numeric(5,2),
 rationale text NOT NULL DEFAULT '',
 assessed_by_run_id uuid REFERENCES agent_runs(id) ON DELETE SET NULL,
 created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE media_assets (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
 case_id uuid NOT NULL REFERENCES news_cases(id) ON DELETE CASCADE,
 revision_id uuid REFERENCES case_revisions(id) ON DELETE SET NULL,
 asset_type text NOT NULL CHECK (asset_type IN ('original_image','derivative_image','thumbnail','document','video','other')),
 storage_ref text NOT NULL,
 original_asset_id uuid REFERENCES media_assets(id) ON DELETE RESTRICT,
 filename text NOT NULL,
 mime_type text NOT NULL,
 size_bytes bigint NOT NULL CHECK(size_bytes >= 0),
 checksum_sha256 text NOT NULL,
 integrity_status text NOT NULL DEFAULT 'pending' CHECK (integrity_status IN ('pending','verified','failed','quarantined')),
 created_by_user_id uuid REFERENCES users(id) ON DELETE SET NULL,
 created_by_run_id uuid REFERENCES agent_runs(id) ON DELETE SET NULL,
 transformations jsonb NOT NULL DEFAULT '[]'::jsonb,
 provenance jsonb NOT NULL DEFAULT '{}'::jsonb,
 created_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE editorial_reviews (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
 case_id uuid NOT NULL REFERENCES news_cases(id) ON DELETE CASCADE,
 revision_id uuid NOT NULL REFERENCES case_revisions(id) ON DELETE RESTRICT,
 draft_id uuid REFERENCES content_drafts(id) ON DELETE RESTRICT,
 reviewer_id uuid NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
 status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','in_review','changes_requested','approved','rejected')),
 comments text NOT NULL DEFAULT '',
 checklist jsonb NOT NULL DEFAULT '{}'::jsonb,
 created_at timestamptz NOT NULL DEFAULT now(),
 updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE approval_records (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
 case_id uuid NOT NULL REFERENCES news_cases(id) ON DELETE CASCADE,
 revision_id uuid NOT NULL REFERENCES case_revisions(id) ON DELETE RESTRICT,
 draft_id uuid NOT NULL REFERENCES content_drafts(id) ON DELETE RESTRICT,
 approved_by uuid NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
 approved_hash text NOT NULL,
 decision text NOT NULL CHECK (decision IN ('approved','rejected','revoked')),
 notes text NOT NULL DEFAULT '',
 created_at timestamptz NOT NULL DEFAULT now(),
 revoked_at timestamptz
);
CREATE TABLE cms_connections (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
 owner_user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
 platform_key text NOT NULL CHECK (platform_key IN ('wordpress_rest','wordpress_com','strapi','ghost','custom')),
 display_name text NOT NULL,
 base_url text NOT NULL,
 integration_instance_id uuid REFERENCES integration_instances(id) ON DELETE SET NULL,
 secret_ref text,
 status integration_status NOT NULL DEFAULT 'draft',
 config jsonb NOT NULL DEFAULT '{}'::jsonb,
 created_at timestamptz NOT NULL DEFAULT now(),
 updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE cms_field_mappings (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
 cms_connection_id uuid NOT NULL REFERENCES cms_connections(id) ON DELETE CASCADE,
 canonical_field text NOT NULL,
 external_field text NOT NULL,
 transform_key text,
 required boolean NOT NULL DEFAULT false,
 UNIQUE(cms_connection_id, canonical_field)
);
CREATE TABLE publish_jobs (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
 case_id uuid NOT NULL REFERENCES news_cases(id) ON DELETE CASCADE,
 revision_id uuid NOT NULL REFERENCES case_revisions(id) ON DELETE RESTRICT,
 draft_id uuid NOT NULL REFERENCES content_drafts(id) ON DELETE RESTRICT,
 cms_connection_id uuid NOT NULL REFERENCES cms_connections(id) ON DELETE RESTRICT,
 status publish_status NOT NULL DEFAULT 'queued',
 idempotency_key text NOT NULL UNIQUE,
 content_hash text NOT NULL,
 approved_hash text NOT NULL,
 external_content_id text,
 external_url text,
 requested_by uuid NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
 requested_at timestamptz NOT NULL DEFAULT now(),
 started_at timestamptz,
 completed_at timestamptz,
 result_payload_redacted jsonb NOT NULL DEFAULT '{}'::jsonb,
 safe_error_message text
);
CREATE TABLE publish_results (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
 publish_job_id uuid NOT NULL REFERENCES publish_jobs(id) ON DELETE CASCADE,
 outcome text NOT NULL CHECK (outcome IN ('draft_created','published','failed','unknown')),
 external_content_id text,
 external_url text,
 response_redacted jsonb NOT NULL DEFAULT '{}'::jsonb,
 observed_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE audit_events (
 id bigserial PRIMARY KEY,
 actor_user_id uuid REFERENCES users(id) ON DELETE SET NULL,
 actor_type text NOT NULL CHECK (actor_type IN ('user','agent','system','integration')),
 action_key text NOT NULL,
 resource_type text NOT NULL,
 resource_id text NOT NULL,
 request_id text,
 before_hash text,
 after_hash text,
 metadata_redacted jsonb NOT NULL DEFAULT '{}'::jsonb,
 created_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE external_requests (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
 integration_instance_id uuid REFERENCES integration_instances(id) ON DELETE SET NULL,
 case_id uuid REFERENCES news_cases(id) ON DELETE SET NULL,
 run_id uuid REFERENCES agent_runs(id) ON DELETE SET NULL,
 request_kind text NOT NULL,
 destination_host text NOT NULL,
 status_code integer,
 latency_ms integer CHECK (latency_ms IS NULL OR latency_ms >= 0),
 attempt_no integer NOT NULL DEFAULT 1 CHECK (attempt_no > 0),
 request_id text,
 safe_error_code text,
 metadata_redacted jsonb NOT NULL DEFAULT '{}'::jsonb,
 created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_cases_status_updated ON news_cases(status, updated_at DESC);
CREATE INDEX idx_sources_case_retrieved ON source_items(case_id, retrieved_at DESC);
CREATE INDEX idx_claims_case_status ON claims(case_id, verification_status);
CREATE INDEX idx_tasks_status_priority ON agent_tasks(status, priority, created_at);
CREATE INDEX idx_tasks_workflow_status ON agent_tasks(workflow_instance_id, status);
CREATE INDEX idx_runs_task_started ON agent_runs(task_id, started_at DESC);
CREATE INDEX idx_events_workflow_created ON workflow_events(workflow_instance_id, created_at);
CREATE INDEX idx_audit_resource_created ON audit_events(resource_type, resource_id, created_at DESC);
CREATE INDEX idx_publish_jobs_status_requested ON publish_jobs(status, requested_at);
CREATE INDEX idx_assets_case_created ON media_assets(case_id, created_at DESC);
CREATE INDEX idx_integrations_status ON integration_instances(status);
CREATE INDEX idx_external_requests_created ON external_requests(created_at DESC);

INSERT INTO roles(role_key,description) VALUES
 ('admin','System configuration and user management'),
 ('editor','Editorial review and approval'),
 ('reporter','Create and revise news cases'),
 ('media_editor','Review and manage media assets'),
 ('viewer','Read-only access')
ON CONFLICT(role_key) DO NOTHING;
INSERT INTO agents(agent_key,display_name,purpose) VALUES
 ('orchestrator','Orchestrator','Plan and dispatch workflow tasks'),
 ('reporter','Reporter','Draft accurate news stories from supported claims'),
 ('verification','Verification','Assess claims against evidence'),
 ('photo_editor','Photo Editor','Create non-deceptive derivatives while preserving originals'),
 ('thumbnail_designer','Thumbnail Designer','Prepare approved thumbnails and crops'),
 ('seo','SEO','Generate accurate SEO metadata without clickbait'),
 ('cms_formatter','CMS Formatter','Map approved content to CMS fields'),
 ('publishing','Publishing','Execute only authorized, approved publish jobs')
ON CONFLICT(agent_key) DO NOTHING;
COMMIT;
