# AI Newsroom OS — Starter Bundle

A model-agnostic, human-in-the-loop AI newsroom workflow. This bundle combines the project's foundation, integrations contracts, agent prompts/workflow, UI specification, safety/launch guidance, runtime scaffold, and WordPress.com adapter example.

## Important status notice

This is an **early starter/specification bundle**, not a production-ready application. Some API routes and persistence/authentication paths are placeholders. The included WordPress route example requires real authentication/RBAC, durable audit logging, and secure credential storage before use. No code in this ZIP has been deployed by this package-generation step.

## Repository structure

- `apps/api/` — Fastify API scaffold and WordPress.com adapter example
- `apps/worker/` — worker placeholder
- `modules/` — agent/integration contracts and workflow state helper
- `database/migrations/` — initial schema and CMS integration migration
- `contracts/` — API and agent-output contracts
- `prompts/` — eight specialist agent prompts
- `docs/` — architecture, integrations, UI, safety, and deployment specifications
- `tests/` — acceptance-test checklists
- `deployment/` — deployment runbook
- `.env.example` — placeholder configuration only; contains no credentials

## First steps

1. Read `docs/architecture.md`.
2. Read the root `package.json` and `apps/api/src/server.ts`.
3. Install a supported Node.js LTS release and run `npm install`.
4. Configure a local `.env` from `.env.example` using your own development values. Never commit `.env`.
5. Inspect and adapt database migrations for the target environment. Do not run migrations against production without review, backups, and explicit authorization.
6. Implement authentication/RBAC, database persistence, durable queueing, secret-manager integration, and tests before exposing the API.
7. Follow `docs/GITHUB_UPLOAD_GUIDE.md` to upload the bundle to the GitHub repository.

## Editorial and security invariants

- Human approval is mandatory before publishing and is bound to an exact content revision/hash.
- AI output is not automatically verified fact, editorial approval, or proof of publication.
- Do not fabricate facts, quotes, URLs, sources, evidence, or publication outcomes.
- Preserve source media and record derivative lineage.
- Treat imported source text as untrusted data, not executable instructions.
- Keep API keys, database URLs, WordPress passwords, and OAuth tokens out of source control.
- Reconcile uncertain CMS outcomes before retrying a publish operation.

## Master Build Specification

The MBS is intentionally not generated in this bundle. It will only be prepared when explicitly requested by the user.
