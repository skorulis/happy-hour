import { barWidthPercent, drinkBarColor } from "@/lib/infographic/drink-bars";
import type { RegionSuburbWinner, TopDensityMetric } from "@/lib/infographic/types";

export type DensityBarRow = RegionSuburbWinner & {
  widthPercent: number;
  color: string;
  isLeader: boolean;
};

export function buildDensityBarRows(
  suburbs: RegionSuburbWinner[],
): DensityBarRow[] {
  if (suburbs.length === 0) return [];
  const maxValue = Math.max(...suburbs.map((suburb) => suburb.value));
  return suburbs.map((suburb, index) => ({
    ...suburb,
    widthPercent: barWidthPercent(suburb.value, maxValue),
    color: drinkBarColor(index),
    isLeader: index === 0,
  }));
}

export function formatDensityBarValue(
  value: number,
  metric: TopDensityMetric,
): string {
  if (metric === "density") {
    return `${value.toFixed(1)}/km²`;
  }
  return value.toLocaleString("en-AU");
}
