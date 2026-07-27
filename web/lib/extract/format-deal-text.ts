import {
  formatTitle,
  normalizeDetails,
} from "./process/text-normalizer";

const NEWLINE_SPLIT = /[\n\r\u2028\u2029\u0085\u000b\u000c]/;

export type FormatDealTextRequest = {
  title?: string | null;
  details?: string | null;
};

export type FormatDealTextResponse = {
  title?: string | null;
  details?: string | null;
};

export type ValidateFormatDealTextResult =
  | { ok: true; value: FormatDealTextRequest }
  | { ok: false; error: string };

function asNullableString(
  value: unknown,
  field: string,
): { ok: true; value: string | null } | { ok: false; error: string } {
  if (value === null) {
    return { ok: true, value: null };
  }
  if (typeof value === "string") {
    return { ok: true, value };
  }
  return { ok: false, error: `Invalid ${field}` };
}

export function validateFormatDealTextRequest(
  body: unknown,
): ValidateFormatDealTextResult {
  if (body === null || typeof body !== "object" || Array.isArray(body)) {
    return { ok: false, error: "Invalid request body" };
  }

  const record = body as Record<string, unknown>;
  const hasTitle = "title" in record;
  const hasDetails = "details" in record;

  if (!hasTitle && !hasDetails) {
    return { ok: false, error: "Missing title or details" };
  }

  const value: FormatDealTextRequest = {};

  if (hasTitle) {
    const title = asNullableString(record.title, "title");
    if (!title.ok) {
      return title;
    }
    value.title = title.value;
  }

  if (hasDetails) {
    const details = asNullableString(record.details, "details");
    if (!details.ok) {
      return details;
    }
    value.details = details.value;
  }

  return { ok: true, value };
}

export function formatDetailsText(details: string): string {
  if (details.length === 0) {
    return details;
  }

  const lines = details.split(NEWLINE_SPLIT);
  return normalizeDetails(lines).join("\n");
}

export function formatDealText(
  request: FormatDealTextRequest,
): FormatDealTextResponse {
  const response: FormatDealTextResponse = {};

  if ("title" in request) {
    const title = request.title ?? "";
    response.title = title.length === 0 ? title : formatTitle(title);
  }

  if ("details" in request) {
    response.details = formatDetailsText(request.details ?? "");
  }

  return response;
}
