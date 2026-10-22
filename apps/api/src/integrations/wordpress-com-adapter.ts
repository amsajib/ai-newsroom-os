/**
 * WordPress.com REST API v1.1 adapter. Server-side only.
 * OAuth access token must come from a secret manager, never from browser input.
 */
export interface WpDraftInput {
  title: string; content: string; excerpt?: string; slug?: string;
  categories?: number[]; tags?: number[];
}
export class WpComError extends Error {
  constructor(public code: string, message: string, public status?: number, public retryable = false) {
    super(message);
  }
}
export class WordPressComAdapter {
  private root = "https://public-api.wordpress.com/rest/v1.1";
  constructor(private site: string, private token: string, private timeoutMs = 12000) {
    if (!/^(?:[a-z0-9-]+\.wordpress\.com|[0-9]+)$/i.test(site)) throw new Error("WP_COM_SITE_INVALID");
    if (!token) throw new Error("WP_COM_TOKEN_REQUIRED");
  }
  private async request<T>(path: string, init: RequestInit = {}): Promise<T> {
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), this.timeoutMs);
    try {
      const response = await fetch(`${this.root}${path}`, {
        ...init, signal: controller.signal,
        headers: {
          Authorization: `Bearer ${this.token}`, Accept: "application/json",
          ...(init.body ? { "Content-Type": "application/x-www-form-urlencoded" } : {}),
          ...init.headers
        }
      });
      const text = await response.text();
      let body: any = {};
      try { body = text ? JSON.parse(text) : {}; } catch {}
      if (!response.ok || body?.error) {
        const status = response.status;
        const code = status === 401 ? "WP_COM_UNAUTHENTICATED" :
          status === 403 ? "WP_COM_FORBIDDEN" : status === 429 ? "WP_COM_RATE_LIMITED" :
          status >= 500 ? "WP_COM_UPSTREAM_ERROR" : "WP_COM_REQUEST_FAILED";
        throw new WpComError(code, "WordPress.com API request failed.", status, status === 429 || status >= 500);
      }
      return body as T;
    } catch (e) {
      if (e instanceof WpComError) throw e;
      if (e instanceof Error && e.name === "AbortError")
        throw new WpComError("WP_COM_TIMEOUT", "WordPress.com API timed out.", undefined, true);
      throw new WpComError("WP_COM_NETWORK_ERROR", "Could not reach WordPress.com API.", undefined, true);
    } finally { clearTimeout(timer); }
  }
  async testConnection() {
    const site = await this.request<any>(`/sites/${encodeURIComponent(this.site)}`);
    return { ok: true as const, site, checkedAt: new Date().toISOString() };
  }
  async createDraft(input: WpDraftInput) {
    if (!input.title.trim() || !input.content.trim()) throw new Error("WP_COM_TITLE_AND_CONTENT_REQUIRED");
    const form = new URLSearchParams({ title: input.title, content: input.content, status: "draft" });
    if (input.excerpt) form.set("excerpt", input.excerpt);
    if (input.slug) form.set("slug", input.slug);
    for (const id of input.categories ?? []) form.append("categories[]", String(id));
    for (const id of input.tags ?? []) form.append("tags[]", String(id));
    return this.request<any>(`/sites/${encodeURIComponent(this.site)}/posts/new`, { method: "POST", body: form.toString() });
  }
  async getPost(id: number) {
    if (!Number.isSafeInteger(id) || id <= 0) throw new Error("WP_COM_POST_ID_INVALID");
    return this.request<any>(`/sites/${encodeURIComponent(this.site)}/posts/${id}`);
  }
  async getCategories() { return this.request<any>(`/sites/${encodeURIComponent(this.site)}/categories?number=100`); }
  async getTags() { return this.request<any>(`/sites/${encodeURIComponent(this.site)}/tags?number=100`); }
}
