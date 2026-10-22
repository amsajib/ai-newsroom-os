export interface IntegrationHealth {
  status: "healthy" | "degraded" | "unavailable" | "configuration_error";
  latencyMs?: number;
  safeMessage: string;
  checkedAt: string;
}

export interface ModelCapabilities {
  textGeneration: boolean;
  vision: boolean;
  structuredOutput: boolean;
  toolCalling: boolean;
  streaming: boolean;
  usageReporting: boolean;
}

export interface NormalizedModelRequest {
  modelId: string;
  systemInstructions: string;
  messages: Array<{ role: "user" | "assistant"; content: string }>;
  maxOutputTokens?: number;
  timeoutMs: number;
  trace: { caseId: string; taskId: string; runId: string; requestId: string };
}

export interface NormalizedModelResponse {
  modelId: string;
  outputText: string;
  usage?: { inputTokens?: number; outputTokens?: number; providerReported: boolean };
  providerRequestId?: string;
  latencyMs: number;
}

export interface ModelAdapter {
  getCapabilities(modelId: string): Promise<ModelCapabilities>;
  generate(request: NormalizedModelRequest): Promise<NormalizedModelResponse>;
  healthCheck(): Promise<IntegrationHealth>;
}

export interface CMSOperationResult {
  outcome: "draft_created" | "published" | "failed" | "unknown";
  externalContentId?: string;
  canonicalUrl?: string;
  safeMessage?: string;
  responseMetadataRedacted: Record<string, unknown>;
}

export interface CMSAdapter {
  validateContent(content: Record<string, unknown>): Promise<{ valid: boolean; issues: string[] }>;
  createDraft(content: Record<string, unknown>, idempotencyKey: string): Promise<CMSOperationResult>;
  publish(content: Record<string, unknown>, idempotencyKey: string): Promise<CMSOperationResult>;
  getPublicationStatus(externalContentId: string): Promise<CMSOperationResult>;
  healthCheck(): Promise<IntegrationHealth>;
}
