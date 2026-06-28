export type CreativeUrlSourceType = "image" | "pdf" | "webpage";

const IMAGE_EXTENSIONS = new Set([
  "jpg",
  "jpeg",
  "png",
  "gif",
  "webp",
  "svg",
  "avif",
]);

export function creativeUrlSourceType(url: string): CreativeUrlSourceType {
  const normalized = url.trim().toLowerCase();

  if (
    normalized.endsWith(".pdf") ||
    (() => {
      try {
        return new URL(url).pathname.toLowerCase().endsWith(".pdf");
      } catch {
        return false;
      }
    })()
  ) {
    return "pdf";
  }

  let extension = "";
  try {
    extension = new URL(url).pathname.split(".").pop()?.toLowerCase() ?? "";
  } catch {
    extension = normalized.split(".").pop()?.split(/[?#]/)[0] ?? "";
  }

  if (IMAGE_EXTENSIONS.has(extension) || normalized.includes("image")) {
    return "image";
  }

  return "webpage";
}

export function isCreativeImageUrl(url: string | null | undefined): url is string {
  if (!url?.trim()) {
    return false;
  }

  return creativeUrlSourceType(url) === "image";
}
