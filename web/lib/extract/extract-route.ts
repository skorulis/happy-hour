import { resolveExtractDealsOpenRouterKey } from "./auth";
import { OpenRouterError } from "./openrouter";
import { runExtractDeals } from "./run-extract";
import {
  MAX_REQUEST_BYTES,
  ValidationError,
  parseExtractDealsRequest,
} from "./validate";
import type { ExtractDealsRequest, ExtractDealsResponse } from "./types";
import { NextResponse } from "next/server";

export type ExtractRouteSuccessHandler = (
  result: ExtractDealsResponse,
  body: ExtractDealsRequest,
) => unknown | Promise<unknown>;

/**
 * Shared POST handler for extract-deals and extract-process-deals.
 * Validates auth/body, runs extraction, then optionally transforms the result.
 */
export async function handleExtractDealsPost(
  request: Request,
  onSuccess: ExtractRouteSuccessHandler = (result) => result,
): Promise<NextResponse> {
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
    const result = await runExtractDeals(credentials.apiKey, body);
    const responseBody = await onSuccess(result, body);
    return NextResponse.json(responseBody);
  } catch (error) {
    if (error instanceof ValidationError) {
      return NextResponse.json(
        { error: error.message },
        { status: error.status },
      );
    }

    if (error instanceof OpenRouterError) {
      const status = error.statusCode === 504 ? 504 : 502;
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
