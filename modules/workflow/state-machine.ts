export type CaseStatus =
  | "draft" | "queued" | "running" | "review_required" | "approved"
  | "publishing" | "published" | "publish_failed" | "blocked" | "cancelled";

const allowed: Record<CaseStatus, ReadonlySet<CaseStatus>> = {
  draft: new Set(["queued", "blocked", "cancelled"]),
  queued: new Set(["running", "blocked", "cancelled"]),
  running: new Set(["review_required", "blocked", "cancelled"]),
  review_required: new Set(["approved", "running", "blocked", "cancelled"]),
  approved: new Set(["review_required", "publishing", "blocked", "cancelled"]),
  publishing: new Set(["published", "publish_failed", "blocked"]),
  published: new Set(["review_required"]), // material correction creates a new review cycle
  publish_failed: new Set(["publishing", "review_required", "blocked", "cancelled"]),
  blocked: new Set(["queued", "running", "review_required", "cancelled"]),
  cancelled: new Set()
};

export function canTransitionCase(current: CaseStatus, next: CaseStatus): boolean {
  return allowed[current].has(next);
}

export function assertApprovalHashMatches(approvedHash: string, currentHash: string): void {
  if (!approvedHash || !currentHash || approvedHash !== currentHash) {
    throw new Error("APPROVAL_HASH_MISMATCH");
  }
}

export function canQueuePublish(input: {
  hasPublishPermission: boolean;
  policyPassed: boolean;
  integrationActive: boolean;
  approvalDecision: "approved" | "rejected" | "revoked" | null;
  approvedHash: string | null;
  currentContentHash: string;
}): boolean {
  return input.hasPublishPermission
    && input.policyPassed
    && input.integrationActive
    && input.approvalDecision === "approved"
    && input.approvedHash !== null
    && input.approvedHash === input.currentContentHash;
}
