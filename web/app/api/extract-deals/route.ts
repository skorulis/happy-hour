import { resolveExtractDealsOpenRouterKey } from "@/lib/extract/auth";
import { buildInstructions } from "@/lib/extract/instructions";
import {
  DEFAULT_OPENROUTER_MODEL,
  OpenRouterError,
  buildOpenRouterRequestBody,
  callOpenRouter,
} from "@/lib/extract/openrouter";
import {
  MAX_REQUEST_BYTES,
  ValidationError,
  parseExtractDealsRequest,
} from "@/lib/extract/validate";
import { NextResponse } from "next/server";

export async function POST(request: Request) {
  const contentLength = request.headers.get("content-length");
  if (contentLength) {
    const length = Number(contentLength);
    if (Number.isFinite(length) && length > MAX_REQUEST_BYTES) {
      return NextResponse.json(
        { error: "Request body too large" },
        { status: 413 },
      );
    }
  }

  const credentials = await resolveExtractDealsOpenRouterKey(request);
  if (!credentials.ok) {
    return NextResponse.json(
      { error: credentials.error },
      { status: credentials.status },
    );
  }

  let rawBody: unknown;
  try {
    rawBody = await request.json();
  } catch {
    return NextResponse.json({ error: "Invalid JSON body" }, { status: 400 });
  }

  try {
    const body = parseExtractDealsRequest(rawBody);
    const model = body.model?.trim() || DEFAULT_OPENROUTER_MODEL;
    const instructions = buildInstructions(body.venueName, body.source);
    const openRouterBody = buildOpenRouterRequestBody(
      model,
      instructions,
      body.source,
    );
    const result = await callOpenRouter(credentials.apiKey, openRouterBody);
    return NextResponse.json(result);
  } catch (error) {
    if (error instanceof ValidationError) {
      return NextResponse.json(
        { error: error.message },
        { status: error.status },
      );
    }

    if (error instanceof OpenRouterError) {
      const status =
        error.statusCode === 504
          ? 504
          : error.statusCode >= 400 && error.statusCode < 500
            ? 502
            : 502;
      console.error("OpenRouter extract-deals failed", error.message);
      return NextResponse.json({ error: error.message }, { status });
    }

    console.error("Failed to extract deals", error);
    return NextResponse.json(
      { error: "Failed to extract deals" },
      { status: 500 },
    );
  }
}
