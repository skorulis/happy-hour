import { buildInstructions } from "./instructions";
import {
  DEFAULT_OPENROUTER_MODEL,
  buildOpenRouterRequestBody,
  callOpenRouter,
} from "./openrouter";
import type { ExtractDealsRequest, ExtractDealsResponse } from "./types";

export async function runExtractDeals(
  apiKey: string,
  body: ExtractDealsRequest,
): Promise<ExtractDealsResponse> {
  const model = body.model?.trim() || DEFAULT_OPENROUTER_MODEL;
  const instructions = buildInstructions(body.venueName, body.source);
  const openRouterBody = buildOpenRouterRequestBody(
    model,
    instructions,
    body.source,
  );
  return callOpenRouter(apiKey, openRouterBody);
}
