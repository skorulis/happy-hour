"use client";

import { useSyncExternalStore, useState } from "react";
import { Check, Download, Link2, Loader2, Share2 } from "lucide-react";
import { domToPng } from "modern-screenshot";

const POSTER_ELEMENT_ID = "region-infographic-poster";

type RegionInfographicShareProps = {
  url: string;
  title: string;
  text: string;
};

function downloadFileName(title: string): string {
  return `${title.replace(/[^\w.-]+/g, "-").toLowerCase()}.png`;
}

function triggerPngDownload(dataUrl: string, filename: string) {
  const anchor = document.createElement("a");
  anchor.href = dataUrl;
  anchor.download = filename;
  document.body.appendChild(anchor);
  anchor.click();
  anchor.remove();
}

async function capturePosterPng(): Promise<string> {
  const poster = document.getElementById(POSTER_ELEMENT_ID);
  if (!poster) {
    throw new Error("Poster element not found");
  }

  // Wait a frame so layout/fonts settle before rasterizing.
  await new Promise<void>((resolve) => {
    requestAnimationFrame(() => resolve());
  });

  const pad = 16;
  const width = poster.offsetWidth + pad * 2;
  const height = poster.offsetHeight + pad * 2;

  return domToPng(poster, {
    scale: 2,
    width,
    height,
    // Page background behind export padding so the card border isn’t clipped.
    backgroundColor: "#081426",
    style: {
      padding: `${pad}px`,
      width: `${width}px`,
      height: `${height}px`,
      boxSizing: "border-box",
      backgroundColor: "#081426",
    },
    filter: (node) => {
      if (!(node instanceof Element)) return true;
      // Skip interactive chrome that shouldn’t appear in the export.
      return !node.hasAttribute("data-infographic-exclude");
    },
  });
}

export function RegionInfographicShare({
  url,
  title,
  text,
}: RegionInfographicShareProps) {
  const [copied, setCopied] = useState(false);
  const [downloading, setDownloading] = useState(false);
  const [status, setStatus] = useState<string | null>(null);
  const canShare = useSyncExternalStore(
    () => () => {},
    () => typeof navigator.share === "function",
    () => false,
  );

  async function copyLink() {
    try {
      await navigator.clipboard.writeText(url);
      setCopied(true);
      setStatus(null);
      window.setTimeout(() => setCopied(false), 2000);
    } catch {
      setStatus("Couldn’t copy the link");
    }
  }

  async function share() {
    try {
      await navigator.share({ title, text, url });
      setStatus(null);
    } catch (error) {
      if (error instanceof DOMException && error.name === "AbortError") {
        return;
      }
      setStatus("Sharing isn’t available here — copy the link instead");
    }
  }

  async function downloadImage() {
    if (downloading) return;
    setDownloading(true);
    setStatus(null);
    try {
      const dataUrl = await capturePosterPng();
      triggerPngDownload(dataUrl, downloadFileName(title));
    } catch {
      setStatus("Couldn’t download the image");
    } finally {
      setDownloading(false);
    }
  }

  return (
    <div className="space-y-2">
      <div className="flex flex-wrap gap-2">
        <button
          type="button"
          onClick={() => void copyLink()}
          className="inline-flex items-center gap-2 rounded-lg border border-border bg-surface-muted px-3 py-2 text-sm font-medium text-foreground transition-colors hover:bg-surface-elevated"
        >
          {copied ? (
            <Check aria-hidden className="h-4 w-4 text-accent-soft" />
          ) : (
            <Link2 aria-hidden className="h-4 w-4" />
          )}
          {copied ? "Copied" : "Copy link"}
        </button>

        {canShare ? (
          <button
            type="button"
            onClick={() => void share()}
            className="inline-flex items-center gap-2 rounded-lg border border-border bg-surface-muted px-3 py-2 text-sm font-medium text-foreground transition-colors hover:bg-surface-elevated"
          >
            <Share2 aria-hidden className="h-4 w-4" />
            Share
          </button>
        ) : null}

        <button
          type="button"
          onClick={() => void downloadImage()}
          disabled={downloading}
          aria-busy={downloading}
          className="inline-flex items-center gap-2 rounded-lg bg-accent px-3 py-2 text-sm font-medium text-accent-fg transition-colors hover:bg-accent-hover disabled:opacity-80"
        >
          {downloading ? (
            <Loader2 aria-hidden className="h-4 w-4 animate-spin" />
          ) : (
            <Download aria-hidden className="h-4 w-4" />
          )}
          {downloading ? "Downloading…" : "Download image"}
        </button>
      </div>
      {status ? <p className="text-sm text-danger">{status}</p> : null}
    </div>
  );
}
