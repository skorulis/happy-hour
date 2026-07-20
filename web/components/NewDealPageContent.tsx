"use client";

import Link from "next/link";
import { useCallback, useEffect, useRef, useState } from "react";
import { useDropzone } from "react-dropzone";
import { EditDealContent } from "@/components/EditDealContent";
import type { ProcessedDeal } from "@/lib/extract/types";

const buttonClassName =
  "w-full rounded-lg bg-accent px-4 py-2 text-sm font-medium text-accent-fg transition-colors hover:bg-accent-hover disabled:cursor-not-allowed disabled:opacity-60";

const MAX_PIXELS = 12_000_000;

const PROCESSING_MESSAGES = [
  "Reading the deal from your image…",
  "Looking for titles, prices, and times…",
  "Sorting out the schedule…",
  "Almost there — finishing up…",
  "Still working — large images can take a minute…",
] as const;

type NewDealPageContentProps = {
  venueName: string;
};

type ScaledImagePayload = {
  base64: string;
  mimeType: string;
};

function blobToBase64(blob: Blob): Promise<string> {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.onload = () => {
      const result = reader.result;
      if (typeof result !== "string") {
        reject(new Error("Failed to read image"));
        return;
      }
      const commaIndex = result.indexOf(",");
      resolve(commaIndex >= 0 ? result.slice(commaIndex + 1) : result);
    };
    reader.onerror = () => reject(reader.error ?? new Error("Failed to read image"));
    reader.readAsDataURL(blob);
  });
}

function scaleImageForUpload(file: File): Promise<ScaledImagePayload> {
  return new Promise((resolve, reject) => {
    const objectUrl = URL.createObjectURL(file);
    const image = new Image();

    image.onload = () => {
      try {
        let { width, height } = image;
        const pixelCount = width * height;

        if (pixelCount >= MAX_PIXELS) {
          const scale = Math.sqrt((MAX_PIXELS - 1) / pixelCount);
          width = Math.max(1, Math.floor(width * scale));
          height = Math.max(1, Math.floor(height * scale));
        }

        const canvas = document.createElement("canvas");
        canvas.width = width;
        canvas.height = height;

        const ctx = canvas.getContext("2d");
        if (!ctx) {
          URL.revokeObjectURL(objectUrl);
          reject(new Error("Failed to prepare image"));
          return;
        }

        ctx.drawImage(image, 0, 0, width, height);

        canvas.toBlob(
          async (blob) => {
            URL.revokeObjectURL(objectUrl);
            if (!blob) {
              reject(new Error("Failed to prepare image"));
              return;
            }
            try {
              const base64 = await blobToBase64(blob);
              resolve({ base64, mimeType: "image/jpeg" });
            } catch (err) {
              reject(err);
            }
          },
          "image/jpeg",
          0.85,
        );
      } catch (err) {
        URL.revokeObjectURL(objectUrl);
        reject(err);
      }
    };

    image.onerror = () => {
      URL.revokeObjectURL(objectUrl);
      reject(new Error("Failed to load image"));
    };

    image.src = objectUrl;
  });
}

export function NewDealPageContent({ venueName }: NewDealPageContentProps) {
  const [file, setFile] = useState<File | null>(null);
  const [previewUrl, setPreviewUrl] = useState<string | null>(null);
  const previewUrlRef = useRef<string | null>(null);
  const [isProcessing, setIsProcessing] = useState(false);
  const [hasProcessed, setHasProcessed] = useState(false);
  const [processingMessageIndex, setProcessingMessageIndex] = useState(0);
  const [error, setError] = useState<string | null>(null);
  const [needsSignIn, setNeedsSignIn] = useState(false);
  const [deals, setDeals] = useState<ProcessedDeal[]>([]);

  useEffect(() => {
    return () => {
      if (previewUrlRef.current) {
        URL.revokeObjectURL(previewUrlRef.current);
        previewUrlRef.current = null;
      }
    };
  }, []);

  useEffect(() => {
    if (!isProcessing) {
      setProcessingMessageIndex(0);
      return;
    }

    const intervalId = window.setInterval(() => {
      setProcessingMessageIndex(
        (index) => (index + 1) % PROCESSING_MESSAGES.length,
      );
    }, 3000);

    return () => {
      window.clearInterval(intervalId);
    };
  }, [isProcessing]);

  const onDrop = useCallback((acceptedFiles: File[]) => {
    const nextFile = acceptedFiles[0];
    if (nextFile) {
      if (previewUrlRef.current) {
        URL.revokeObjectURL(previewUrlRef.current);
      }
      const objectUrl = URL.createObjectURL(nextFile);
      previewUrlRef.current = objectUrl;
      setFile(nextFile);
      setPreviewUrl(objectUrl);
      setError(null);
      setNeedsSignIn(false);
      setHasProcessed(false);
      setDeals([]);
    }
  }, []);

  const { getRootProps, getInputProps, isDragActive } = useDropzone({
    onDrop,
    accept: { "image/*": [] },
    maxFiles: 1,
    multiple: false,
    disabled: isProcessing,
  });

  const processImage = useCallback(async () => {
    if (!file || isProcessing) {
      return;
    }

    setIsProcessing(true);
    setError(null);
    setNeedsSignIn(false);
    setHasProcessed(false);
    setDeals([]);

    try {
      const { base64: imageBase64, mimeType } = await scaleImageForUpload(file);
      const response = await fetch("/api/extract-process-deals", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          venueName,
          source: {
            type: "image",
            url: file.name || "uploaded-image",
            imageBase64,
            mimeType,
          },
        }),
      });

      const payload = (await response.json()) as {
        deals?: ProcessedDeal[];
        error?: string;
      };

      if (response.status === 401) {
        setNeedsSignIn(true);
        setError("Sign in to process images");
        return;
      }

      if (!response.ok) {
        throw new Error(payload.error ?? "Failed to extract deals");
      }

      setDeals(payload.deals ?? []);
      setHasProcessed(true);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to extract deals");
    } finally {
      setIsProcessing(false);
    }
  }, [file, isProcessing, venueName]);

  return (
    <div className="flex flex-col gap-6">
      <h1 className="text-3xl font-bold text-foreground">
        Add a new deal to {venueName}
      </h1>

      <div
        {...getRootProps()}
        className={`flex cursor-pointer flex-col items-center justify-center rounded-xl border border-dashed px-6 py-10 transition-colors ${
          isDragActive
            ? "border-accent bg-accent-muted"
            : "border-border bg-surface-muted hover:border-accent"
        } ${isProcessing ? "pointer-events-none opacity-60" : ""}`}
      >
        <input {...getInputProps()} />
        {previewUrl ? (
          // eslint-disable-next-line @next/next/no-img-element
          <img
            src={previewUrl}
            alt="Selected deal photo"
            className="max-h-80 w-full rounded-lg object-contain"
          />
        ) : (
          <p className="text-center text-sm text-secondary">
            Select the image that shows the deal
          </p>
        )}
      </div>

      {file && !hasProcessed ? (
        <div className="flex flex-col gap-2">
          <button
            type="button"
            className={buttonClassName}
            onClick={() => {
              void processImage();
            }}
            disabled={isProcessing}
          >
            {isProcessing ? "Processing…" : "Process image"}
          </button>
          {isProcessing ? (
            <p className="text-center text-sm text-secondary" aria-live="polite">
              {PROCESSING_MESSAGES[processingMessageIndex]}
            </p>
          ) : null}
        </div>
      ) : null}

      {error ? (
        <p className="text-sm text-danger" role="alert">
          {needsSignIn ? (
            <>
              Sign in to process images.{" "}
              <Link href="/login" className="underline hover:text-foreground">
                Sign in
              </Link>
            </>
          ) : (
            error
          )}
        </p>
      ) : null}

      {deals.length > 0 ? (
        <div className="flex flex-col gap-3">
          <h2 className="text-lg font-semibold text-foreground">
            Extracted {deals.length} {deals.length === 1 ? "deal" : "deals"}
          </h2>
          <div className="flex flex-col gap-4">
            {deals.map((deal, index) => (
              <EditDealContent
                key={index}
                deal={deal}
                onChange={(next) => {
                  setDeals((prev) =>
                    prev.map((current, i) => (i === index ? next : current)),
                  );
                }}
              />
            ))}
          </div>
        </div>
      ) : null}
    </div>
  );
}
