export const FAVORITES_STORAGE_KEY = "happy-hour:favorite-deals";

function parseFavoriteDealIds(raw: string | null): number[] {
  if (!raw) {
    return [];
  }

  try {
    const parsed: unknown = JSON.parse(raw);
    if (!Array.isArray(parsed)) {
      return [];
    }

    return parsed.filter(
      (value): value is number =>
        typeof value === "number" && Number.isInteger(value) && value > 0,
    );
  } catch {
    return [];
  }
}

export function readFavoriteDealIds(
  storage: Pick<Storage, "getItem"> = localStorage,
): number[] {
  try {
    return parseFavoriteDealIds(storage.getItem(FAVORITES_STORAGE_KEY));
  } catch {
    return [];
  }
}

export function writeFavoriteDealIds(
  ids: number[],
  storage: Pick<Storage, "setItem"> = localStorage,
): void {
  try {
    storage.setItem(FAVORITES_STORAGE_KEY, JSON.stringify(ids));
  } catch {
    // Ignore quota errors and private browsing restrictions.
  }
}

export function toggleFavoriteDealId(
  ids: number[],
  dealId: number,
): number[] {
  if (ids.includes(dealId)) {
    return ids.filter((id) => id !== dealId);
  }

  return [...ids, dealId];
}
