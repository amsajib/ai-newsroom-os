export type ClaimStatus = "VERIFIED" | "PARTIALLY_VERIFIED" | "UNVERIFIED" | "CONTRADICTED";

export interface AgentClaim {
  claim: string;
  classification: string;
  evidence: Array<{
    source_ref: string | null;
    excerpt: string;
    relation: "supports" | "contradicts" | "context_only" | "none";
  }>;
  source_url: string | null;
  source_reliability: "high" | "medium" | "low" | "unknown";
  verification_status: ClaimStatus;
  reason: string;
}

export interface AgentOutput {
  schema_version: "1.0";
  case_id: string;
  task_id: string;
  agent_id: string;
  run_id: string;
  status: "completed" | "blocked" | "failed" | "needs_human";
  created_at: string;
  input_refs: string[];
  data: Record<string, unknown>;
  claims: AgentClaim[];
  warnings: string[];
  errors: Array<{ code: string; message: string; retryable?: boolean }>;
  validation: {
    schema_valid: boolean;
    required_fields_present: boolean;
    blocking_issues: string[];
  };
  handoff: {
    next_agent_id: string | null;
    required_input_refs: string[];
    handoff_status: "pending" | "ready" | "blocked" | "not_required";
  };
}
