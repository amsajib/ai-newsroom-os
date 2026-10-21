# AI Newsroom OS

A model-agnostic, human-in-the-loop AI newsroom workflow.

## Core workflow
Source intake → Claim verification → Reporting → Media preparation
→ SEO → CMS formatting → Human approval → Publishing → Audit

## Core agents
1. Orchestrator
2. Reporter
3. Verification
4. Photo Editor
5. Thumbnail Designer
6. SEO
7. CMS Formatter
8. Publishing

## Safety requirements
- Human approval before publication.
- Approval bound to the exact content revision/hash.
- No invented facts, quotes, sources, or evidence.
- Preserve original media and track derivatives.
- Never commit API keys, tokens, or database credentials.
- Reconcile uncertain CMS results before retrying publication.

## Status
Early development. Not production-ready.