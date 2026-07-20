import { auth } from "@/lib/auth";

export type ResolveOpenRouterKeyResult =
  | { ok: true; apiKey: string; source: "client" | "server" }
  | { ok: false; error: string; status: 401 | 503 };

function parseBearerOpenRouterKey(
  authorizationHeader: string | null,
): string | null {
  if (!authorizationHeader) {
    return null;
  }

  const match = /^Bearer\s+(.+)$/i.exec(authorizationHeader.trim());
  if (!match?.[1]) {
    return null;
  }

  const token = match[1].trim();
  if (!token.startsWith("sk-or-")) {
    return null;
  }

  return token;
}

export async function resolveExtractDealsOpenRouterKey(
  request: Request,
): Promise<ResolveOpenRouterKeyResult> {
  const clientKey = parseBearerOpenRouterKey(
    request.headers.get("authorization"),
  );
  if (clientKey) {
    return { ok: true, apiKey: clientKey, source: "client" };
  }

  const session = await auth.api.getSession({ headers: request.headers });
  if (!session?.user.id) {
    return { ok: false, error: "Unauthorized", status: 401 };
  }

  const serverKey = process.env.OPENROUTER_API_KEY?.trim();
  if (!serverKey) {
    console.error("OPENROUTER_API_KEY is not configured");
    return {
      ok: false,
      error: "Deal extraction is not configured",
      status: 503,
    };
  }

  if (!serverKey.startsWith("sk-or-")) {
    console.error(
      "OPENROUTER_API_KEY does not look like an OpenRouter key (expected sk-or-…)",
    );
    return {
      ok: false,
      error:
        "OPENROUTER_API_KEY must be an OpenRouter key (sk-or-…), not an OpenAI key",
      status: 503,
    };
  }

  return { ok: true, apiKey: serverKey, source: "server" };
}
