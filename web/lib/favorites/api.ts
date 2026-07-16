export async function fetchFavorites(): Promise<number[]> {
  const response = await fetch("/api/favorites", {
    credentials: "include",
  });

  if (!response.ok) {
    throw new Error("Failed to fetch favorites");
  }

  const data = (await response.json()) as { dealIds?: unknown };

  if (!Array.isArray(data.dealIds)) {
    return [];
  }

  return data.dealIds.filter(
    (value): value is number =>
      typeof value === "number" && Number.isInteger(value) && value > 0,
  );
}

export async function setFavorite(
  dealId: number,
  favorited: boolean,
): Promise<number[]> {
  const response = await fetch("/api/favorites", {
    method: "POST",
    credentials: "include",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ dealId, favorited }),
  });

  if (!response.ok) {
    throw new Error("Failed to set favorite");
  }

  const data = (await response.json()) as { dealIds?: unknown };

  if (!Array.isArray(data.dealIds)) {
    return [];
  }

  return data.dealIds.filter(
    (value): value is number =>
      typeof value === "number" && Number.isInteger(value) && value > 0,
  );
}
