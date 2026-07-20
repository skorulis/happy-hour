import { describe, expect, it, vi, beforeEach, afterEach } from "vitest";

vi.mock("@/lib/auth", () => ({
  auth: {
    api: {
      getSession: vi.fn(),
    },
  },
}));

import { auth } from "@/lib/auth";
import { resolveExtractDealsOpenRouterKey } from "@/lib/extract/auth";

const getSession = auth.api.getSession as ReturnType<typeof vi.fn>;

describe("resolveExtractDealsOpenRouterKey", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    delete process.env.OPENROUTER_API_KEY;
  });

  afterEach(() => {
    delete process.env.OPENROUTER_API_KEY;
  });

  it("uses client Bearer sk-or key without requiring a session", async () => {
    const request = new Request("http://localhost/api/extract-deals", {
      headers: { Authorization: "Bearer sk-or-v1-test-key" },
    });

    const result = await resolveExtractDealsOpenRouterKey(request);

    expect(result).toEqual({
      ok: true,
      apiKey: "sk-or-v1-test-key",
      source: "client",
    });
    expect(getSession).not.toHaveBeenCalled();
  });

  it("rejects non OpenRouter bearer tokens and falls through to session", async () => {
    getSession.mockResolvedValue(null);
    const request = new Request("http://localhost/api/extract-deals", {
      headers: { Authorization: "Bearer sk-proj-openai" },
    });

    const result = await resolveExtractDealsOpenRouterKey(request);

    expect(result).toEqual({
      ok: false,
      error: "Unauthorized",
      status: 401,
    });
    expect(getSession).toHaveBeenCalledOnce();
  });

  it("uses server key for logged-in sessions", async () => {
    process.env.OPENROUTER_API_KEY = "sk-or-v1-server";
    getSession.mockResolvedValue({ user: { id: "user-1" } });

    const result = await resolveExtractDealsOpenRouterKey(
      new Request("http://localhost/api/extract-deals"),
    );

    expect(result).toEqual({
      ok: true,
      apiKey: "sk-or-v1-server",
      source: "server",
    });
  });
});
