CREATE SCHEMA IF NOT EXISTS newsroom;
CREATE TABLE IF NOT EXISTS newsroom.integration_instances (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
 integration_type text NOT NULL CHECK (integration_type IN ('ai_provider','source','media','cms')),
 adapter_key text NOT NULL, display_name text NOT NULL, base_url text,
 status text NOT NULL DEFAULT 'draft' CHECK (status IN ('draft','active','disabled','error')),
 config jsonb NOT NULL DEFAULT '{}'::jsonb, credential_secret_ref text,
 capabilities jsonb NOT NULL DEFAULT '{}'::jsonb, last_health_check jsonb,
 created_by text, created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz NOT NULL DEFAULT now(),
 CONSTRAINT integration_secret_ref_not_inline CHECK (
  NOT (config ? 'apiKey') AND NOT (config ? 'password') AND NOT (config ? 'applicationPassword')
  AND NOT (config ? 'accessToken') AND NOT (config ? 'secret'))
);
CREATE INDEX IF NOT EXISTS integration_instances_type_status_idx ON newsroom.integration_instances(integration_type,status);
CREATE TABLE IF NOT EXISTS newsroom.cms_field_mappings (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
 integration_instance_id uuid NOT NULL REFERENCES newsroom.integration_instances(id) ON DELETE RESTRICT,
 mapping_version integer NOT NULL DEFAULT 1, mapping jsonb NOT NULL DEFAULT '{}'::jsonb,
 status text NOT NULL DEFAULT 'draft' CHECK(status IN ('draft','active','disabled')),
 created_at timestamptz NOT NULL DEFAULT now(), UNIQUE(integration_instance_id,mapping_version)
);
CREATE TABLE IF NOT EXISTS newsroom.external_requests (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
 integration_instance_id uuid NOT NULL REFERENCES newsroom.integration_instances(id) ON DELETE RESTRICT,
 operation text NOT NULL, idempotency_key text, request_metadata_redacted jsonb NOT NULL DEFAULT '{}'::jsonb,
 response_metadata_redacted jsonb NOT NULL DEFAULT '{}'::jsonb,
 status text NOT NULL CHECK(status IN ('started','succeeded','failed','unknown_needs_reconciliation')),
 external_request_id text, created_at timestamptz NOT NULL DEFAULT now(), completed_at timestamptz
);
CREATE UNIQUE INDEX IF NOT EXISTS external_requests_idempotency_idx
 ON newsroom.external_requests(integration_instance_id,idempotency_key) WHERE idempotency_key IS NOT NULL;
CREATE TABLE IF NOT EXISTS newsroom.publish_jobs (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
 integration_instance_id uuid NOT NULL REFERENCES newsroom.integration_instances(id) ON DELETE RESTRICT,
 case_id uuid, revision_id uuid, content_hash text NOT NULL, approved_hash text, approval_id uuid,
 status text NOT NULL CHECK(status IN ('queued','running','draft_created','published','failed','unknown_needs_reconciliation','cancelled')),
 idempotency_key text NOT NULL UNIQUE, external_content_id text, canonical_url text, safe_error_code text,
 created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz NOT NULL DEFAULT now(), completed_at timestamptz,
 CONSTRAINT publish_job_hash_gate CHECK(status <> 'published' OR (approved_hash IS NOT NULL AND approved_hash = content_hash))
);
CREATE INDEX IF NOT EXISTS publish_jobs_status_created_idx ON newsroom.publish_jobs(status,created_at DESC);
