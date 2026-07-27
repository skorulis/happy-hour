"use client";

import { useEffect, useState } from "react";
import { Check, Download, Link2, Share2 } from "lucide-react";

type RegionInfographicShareProps = {
  url: string;
  title: string;
  text: string;
  downloadPath: string;
};

export function RegionInfographicShare({
  url,
  title,
  text,
  downloadPath,
}: RegionInfographicShareProps) {
  const [copied, setCopied] = useState(false);
  const [status, setStatus] = useState<string | null>(null);
  // Detect Web Share after mount — navigator.share differs between SSR and client.
  const [canShare, setCanShare] = useState(false);

  useEffect(() => {
    setCanShare(typeof navigator.share === "function");
  }, []);

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
    try {
      const response = await fetch(downloadPath);
      if (!response.ok) {
        throw new Error(`Download failed (${response.status})`);
      }
      const blob = await response.blob();
      const objectUrl = URL.createObjectURL(blob);
      const anchor = document.createElement("a");
      anchor.href = objectUrl;
      anchor.download = `${title.replace(/[^\w.-]+/g, "-").toLowerCase()}.png`;
      document.body.appendChild(anchor);
      anchor.click();
      anchor.remove();
      URL.revokeObjectURL(objectUrl);
      setStatus(null);
    } catch {
      setStatus("Couldn’t download the image");
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
          className="inline-flex items-center gap-2 rounded-lg bg-accent px-3 py-2 text-sm font-medium text-accent-fg transition-colors hover:bg-accent-hover"
        >
          <Download aria-hidden className="h-4 w-4" />
          Download image
        </button>
      </div>
      {status ? <p className="text-sm text-danger">{status}</p> : null}
    </div>
  );
}
