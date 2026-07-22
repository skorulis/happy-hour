import { describe, expect, it } from "vitest";
import {
  cleanSvgPath,
  createAustraliaProjection,
  buildRegionPaths,
} from "@/lib/regions/map-projection";

describe("cleanSvgPath", () => {
  it("removes zero-height antimeridian clip segments", () => {
    const path =
      "M10,10L20,20L15,25ZM100,5L500,5L500,5Z";
    expect(cleanSvgPath(path)).toBe("M10,10L20,20L15,25Z");
  });
});

describe("buildRegionPaths", () => {
  it("produces bounded paths for known regions", () => {
    const projection = createAustraliaProjection();
    const paths = buildRegionPaths(projection);
    const bySlug = new Map(
      paths
        .filter((entry) => entry.slug !== null)
        .map((entry) => [entry.slug!, entry.path]),
    );

    expect(bySlug.has("sydney")).toBe(true);
    expect(bySlug.has("sunshine-coast")).toBe(true);

    for (const path of bySlug.values()) {
      expect(path).not.toMatch(/L-?\d{4,}/);
      const numbers = path.match(/-?\d+\.?\d*/g)?.map(Number) ?? [];
      const xs = numbers.filter((_, index) => index % 2 === 0);
      const ys = numbers.filter((_, index) => index % 2 === 1);
      expect(Math.max(...xs) - Math.min(...xs)).toBeLessThan(800);
      expect(Math.max(...ys) - Math.min(...ys)).toBeLessThan(600);
    }
  });
});
