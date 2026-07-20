import {
  markdownExtractionTask,
  pdfExtractionTask,
  webpageExtractionTask,
} from "./instructions";
import { responseFormat } from "./schema";
import type {
  ExtractDealsResponse,
  ExtractDealsSource,
  ExtractedDeal,
} from "./types";

export const DEFAULT_OPENROUTER_MODEL = "google/gemini-2.5-pro";
export const OPENROUTER_CHAT_URL =
  "https://openrouter.ai/api/v1/chat/completions";
export const OPENROUTER_TIMEOUT_MS = 120_000;

export class OpenRouterError extends Error {
  constructor(
    message: string,
    readonly statusCode: number,
  ) {
    super(message);
    this.name = "OpenRouterError";
  }
}

type ChatCompletionResponse = {
  choices?: Array<{
    message?: {
      content?: string | null;
    };
  }>;
  error?: {
    message?: string;
  };
};

function toStringArray(value: unknown): string[] {
  if (Array.isArray(value)) {
    return value.filter((item): item is string => typeof item === "string");
  }
  if (typeof value === "string") {
    return [value];
  }
  return [];
}

function toOptionalStringArray(value: unknown): string[] | null {
  if (value === null || value === undefined) {
    return null;
  }
  return toStringArray(value);
}

function normalizeDeal(raw: unknown): ExtractedDeal | null {
  if (!raw || typeof raw !== "object") {
    return null;
  }

  const deal = raw as Record<string, unknown>;
  if (typeof deal.title !== "string") {
    return null;
  }

  return {
    title: deal.title,
    details: toStringArray(deal.details),
    conditions: toStringArray(deal.conditions),
    days: toStringArray(deal.days),
    times: toStringArray(deal.times),
    promotionDates: toOptionalStringArray(deal.promotionDates),
  };
}

export function stripMarkdownCodeFence(content: string): string {
  let trimmed = content.trim();
  if (!trimmed.startsWith("```")) {
    return trimmed;
  }

  const firstNewline = trimmed.indexOf("\n");
  if (firstNewline !== -1) {
    trimmed = trimmed.slice(firstNewline + 1);
  }
  if (trimmed.endsWith("```")) {
    trimmed = trimmed.slice(0, -3);
  }
  return trimmed.trim();
}

export function parseDealExtractionPayload(
  content: string,
): ExtractDealsResponse {
  const jsonString = stripMarkdownCodeFence(content);
  const parsed: unknown = JSON.parse(jsonString);

  if (Array.isArray(parsed)) {
    return {
      deals: parsed
        .map(normalizeDeal)
        .filter((deal): deal is ExtractedDeal => deal != null),
    };
  }

  if (parsed && typeof parsed === "object" && "deals" in parsed) {
    const deals = (parsed as { deals: unknown }).deals;
    if (Array.isArray(deals)) {
      return {
        deals: deals
          .map(normalizeDeal)
          .filter((deal): deal is ExtractedDeal => deal != null),
      };
    }
  }

  throw new Error("Failed to decode deal extraction payload");
}

function buildImageRequestBody(
  model: string,
  instructions: string,
  imageURL: string,
) {
  return {
    model,
    messages: [
      { role: "system", content: instructions },
      {
        role: "user",
        content: [
          {
            type: "text",
            text: "Extract all deals from this pub or restaurant poster image.",
          },
          {
            type: "image_url",
            image_url: { url: imageURL },
          },
        ],
      },
    ],
    response_format: responseFormat,
  };
}

function buildTextRequestBody(
  model: string,
  instructions: string,
  extractionTask: string,
  text: string,
) {
  return {
    model,
    messages: [
      { role: "system", content: instructions },
      {
        role: "user",
        content: `${extractionTask}\n\n${text}`,
      },
    ],
    response_format: responseFormat,
  };
}

function buildWebpageFetchRequestBody(
  model: string,
  instructions: string,
  webpageURL: string,
) {
  return {
    model,
    messages: [
      { role: "system", content: instructions },
      {
        role: "user",
        content: `${webpageExtractionTask}\n\n${webpageURL}`,
      },
    ],
    tools: [
      {
        type: "openrouter:web_fetch",
        parameters: { max_uses: 1 },
      },
    ],
    response_format: responseFormat,
  };
}

export function buildOpenRouterRequestBody(
  model: string,
  instructions: string,
  source: ExtractDealsSource,
): Record<string, unknown> {
  if (source.type === "image") {
    if (source.imageBase64) {
      const mimeType = source.mimeType ?? "image/png";
      return buildImageRequestBody(
        model,
        instructions,
        `data:${mimeType};base64,${source.imageBase64}`,
      );
    }
    if (source.imageUrl) {
      return buildImageRequestBody(model, instructions, source.imageUrl);
    }
    throw new Error("Image source requires imageBase64 or imageUrl");
  }

  if (source.type === "pdf") {
    if (!source.text) {
      throw new Error("PDF source requires text");
    }
    return buildTextRequestBody(
      model,
      instructions,
      pdfExtractionTask,
      source.text,
    );
  }

  // webpage
  if (source.markdown != null && source.markdown.length > 0) {
    return buildTextRequestBody(
      model,
      instructions,
      markdownExtractionTask,
      source.markdown,
    );
  }

  return buildWebpageFetchRequestBody(model, instructions, source.url);
}

export async function callOpenRouter(
  apiKey: string,
  body: Record<string, unknown>,
): Promise<ExtractDealsResponse> {
  const referer =
    process.env.NEXT_PUBLIC_SITE_URL?.trim() ||
    process.env.BETTER_AUTH_URL?.trim() ||
    "https://duskroute.com";

  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), OPENROUTER_TIMEOUT_MS);

  try {
    const response = await fetch(OPENROUTER_CHAT_URL, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${apiKey}`,
        "Content-Type": "application/json",
        "HTTP-Referer": referer,
        "X-Title": "duskroute",
      },
      body: JSON.stringify(body),
      signal: controller.signal,
    });

    const responseText = await response.text();
    let json: ChatCompletionResponse;
    try {
      json = JSON.parse(responseText) as ChatCompletionResponse;
    } catch {
      throw new OpenRouterError(
        response.ok
          ? "Invalid JSON from OpenRouter"
          : `OpenRouter error (${response.status})`,
        response.status,
      );
    }

    if (!response.ok) {
      const message =
        json.error?.message ?? `OpenRouter request failed (${response.status})`;
      throw new OpenRouterError(message, response.status);
    }

    const content = json.choices?.[0]?.message?.content;
    if (!content) {
      throw new OpenRouterError("Empty OpenRouter response", 502);
    }

    return parseDealExtractionPayload(content);
  } catch (error) {
    if (error instanceof OpenRouterError) {
      throw error;
    }
    if (error instanceof Error && error.name === "AbortError") {
      throw new OpenRouterError("OpenRouter request timed out", 504);
    }
    throw error;
  } finally {
    clearTimeout(timeout);
  }
}
