import { findMatchingProductsForDeals } from "@data/products";

export type ExtractProductsRequest = {
  title: string | null;
  details: string | null;
};

export type ExtractedProduct = {
  name: string;
  price: null;
};

export type ExtractProductsResponse = {
  products: ExtractedProduct[];
};

export type ValidateExtractProductsResult =
  | { ok: true; value: ExtractProductsRequest }
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

export function validateExtractProductsRequest(
  body: unknown,
): ValidateExtractProductsResult {
  if (body === null || typeof body !== "object" || Array.isArray(body)) {
    return { ok: false, error: "Invalid request body" };
  }

  const record = body as Record<string, unknown>;

  if (!("title" in record)) {
    return { ok: false, error: "Missing title" };
  }
  if (!("details" in record)) {
    return { ok: false, error: "Missing details" };
  }

  const title = asNullableString(record.title, "title");
  if (!title.ok) {
    return title;
  }

  const details = asNullableString(record.details, "details");
  if (!details.ok) {
    return details;
  }

  return {
    ok: true,
    value: {
      title: title.value,
      details: details.value,
    },
  };
}

export function extractProducts(
  request: ExtractProductsRequest,
): ExtractProductsResponse {
  const matches = findMatchingProductsForDeals([
    {
      title: request.title,
      details: request.details,
      conditions: null,
    },
  ]);

  return {
    products: matches.map((product) => ({
      name: product.name,
      price: null,
    })),
  };
}
