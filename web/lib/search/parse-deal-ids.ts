export const MAX_DEAL_IDS_PARAM = 200;

export type ParseDealIdsResult =
  | { ok: true; ids: number[] }
  | { ok: false; error: string };

export function parseDealIdsParam(value: string | null): ParseDealIdsResult {
  if (value === null || value.trim() === "") {
    return { ok: true, ids: [] };
  }

  const parts = value.split(",").map((part) => part.trim());
  if (parts.some((part) => part === "")) {
    return { ok: false, error: "Invalid ids" };
  }

  const ids: number[] = [];
  for (const part of parts) {
    const id = Number(part);
    if (!Number.isInteger(id) || id <= 0) {
      return { ok: false, error: "Invalid ids" };
    }
    ids.push(id);
  }

  if (ids.length > MAX_DEAL_IDS_PARAM) {
    return {
      ok: false,
      error: `Too many ids (max ${MAX_DEAL_IDS_PARAM})`,
    };
  }

  return { ok: true, ids };
}
