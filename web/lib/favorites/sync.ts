export function unionFavoriteDealIds(
  localIds: number[],
  serverIds: number[],
): number[] {
  const seen = new Set<number>();
  const merged: number[] = [];

  for (const id of [...localIds, ...serverIds]) {
    if (seen.has(id)) {
      continue;
    }
    seen.add(id);
    merged.push(id);
  }

  return merged;
}
