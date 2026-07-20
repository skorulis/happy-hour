import type { ExtractDealsRequest, ExtractDealsSource, ExtractSourceType } from "./types";

/** Max decoded image size (~6MB). */
export const MAX_IMAGE_BYTES = 6 * 1024 * 1024;

/** Approx max JSON body (~10MB) including base64 overhead. */
export const MAX_REQUEST_BYTES = 10 * 1024 * 1024;

/** Max markdown / PDF text characters. */
export const MAX_TEXT_CHARS = 500_000;

export class ValidationError extends Error {
  constructor(
    message: string,
    readonly status: 400 | 413 = 400,
  ) {
    super(message);
    this.name = "ValidationError";
  }
}

function isSourceType(value: unknown): value is ExtractSourceType {
  return value === "image" || value === "webpage" || value === "pdf";
}

function asOptionalString(value: unknown): string | undefined {
  if (value === undefined || value === null) {
    return undefined;
  }
  if (typeof value !== "string") {
    throw new ValidationError("Expected string field");
  }
  return value;
}

function asRequiredString(value: unknown, field: string): string {
  if (typeof value !== "string" || value.trim().length === 0) {
    throw new ValidationError(`Missing or invalid ${field}`);
  }
  return value;
}

function estimateBase64DecodedBytes(base64: string): number {
  const trimmed = base64.replace(/\s/g, "");
  const padding = trimmed.endsWith("==") ? 2 : trimmed.endsWith("=") ? 1 : 0;
  return Math.floor((trimmed.length * 3) / 4) - padding;
}

function validateSource(raw: unknown): ExtractDealsSource {
  if (!raw || typeof raw !== "object") {
    throw new ValidationError("Missing or invalid source");
  }

  const source = raw as Record<string, unknown>;

  if (!isSourceType(source.type)) {
    throw new ValidationError("source.type must be image, webpage, or pdf");
  }

  const url = asRequiredString(source.url, "source.url");
  const sourceURL = asOptionalString(source.sourceURL);
  const index =
    source.index === undefined
      ? undefined
      : typeof source.index === "number" &&
          Number.isFinite(source.index) &&
          Number.isInteger(source.index) &&
          source.index > 0
        ? source.index
        : (() => {
            throw new ValidationError("source.index must be a positive integer");
          })();

  const imageBase64 = asOptionalString(source.imageBase64);
  const mimeType = asOptionalString(source.mimeType);
  const imageUrl = asOptionalString(source.imageUrl);
  const markdown = asOptionalString(source.markdown);
  const text = asOptionalString(source.text);

  if (imageBase64) {
    const decodedBytes = estimateBase64DecodedBytes(imageBase64);
    if (decodedBytes > MAX_IMAGE_BYTES) {
      throw new ValidationError(
        `Image exceeds maximum size of ${MAX_IMAGE_BYTES} bytes`,
        413,
      );
    }
  }

  if (markdown && markdown.length > MAX_TEXT_CHARS) {
    throw new ValidationError("Markdown exceeds maximum length", 413);
  }

  if (text && text.length > MAX_TEXT_CHARS) {
    throw new ValidationError("Text exceeds maximum length", 413);
  }

  if (source.type === "image") {
    if (!imageBase64 && !imageUrl) {
      throw new ValidationError(
        "Image source requires imageBase64 or imageUrl",
      );
    }
  }

  if (source.type === "pdf") {
    if (!text || text.trim().length === 0) {
      throw new ValidationError("PDF source requires text");
    }
  }

  return {
    type: source.type,
    index,
    url,
    sourceURL,
    imageBase64,
    mimeType,
    imageUrl,
    markdown,
    text,
  };
}

export function parseExtractDealsRequest(
  raw: unknown,
): ExtractDealsRequest {
  if (!raw || typeof raw !== "object") {
    throw new ValidationError("Invalid JSON body");
  }

  const body = raw as Record<string, unknown>;
  const venueName = asRequiredString(body.venueName, "venueName");
  const model = asOptionalString(body.model);
  const source = validateSource(body.source);

  return {
    venueName,
    model: model?.trim() || undefined,
    source,
  };
}
