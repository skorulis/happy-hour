"use client";

import Link from "next/link";
import { useCallback, useEffect, useState } from "react";
import { useDropzone } from "react-dropzone";

const buttonClassName =
  "w-full rounded-lg bg-accent px-4 py-2 text-sm font-medium text-accent-fg transition-colors hover:bg-accent-hover disabled:cursor-not-allowed disabled:opacity-60";

type ExtractedDeal = {
  title: string;
  details: string[];
  conditions: string[];
  days: string[];
  times: string[];
  promotionDates: string[] | null;
};

type NewDealPageContentProps = {
  venueName: string;
};

function fileToBase64(file: File): Promise<string> {
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
    reader.readAsDataURL(file);
  });
}

export function NewDealPageContent({ venueName }: NewDealPageContentProps) {
  const [file, setFile] = useState<File | null>(null);
  const [previewUrl, setPreviewUrl] = useState<string | null>(null);
  const [isProcessing, setIsProcessing] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [needsSignIn, setNeedsSignIn] = useState(false);
  const [deals, setDeals] = useState<ExtractedDeal[]>([]);

  useEffect(() => {
    if (!file) {
      setPreviewUrl(null);
      return;
    }

    const objectUrl = URL.createObjectURL(file);
    setPreviewUrl(objectUrl);

    return () => {
      URL.revokeObjectURL(objectUrl);
    };
  }, [file]);

  const onDrop = useCallback((acceptedFiles: File[]) => {
    const nextFile = acceptedFiles[0];
    if (nextFile) {
      setFile(nextFile);
      setError(null);
      setNeedsSignIn(false);
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
    setDeals([]);

    try {
      const imageBase64 = await fileToBase64(file);
      const response = await fetch("/api/extract-deals", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          venueName,
          source: {
            type: "image",
            url: file.name || "uploaded-image",
            imageBase64,
            mimeType: file.type || "image/png",
          },
        }),
      });

      const payload = (await response.json()) as {
        deals?: ExtractedDeal[];
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

      {file ? (
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
            Extracted deals
          </h2>
          <ul className="flex flex-col gap-2">
            {deals.map((deal, index) => (
              <li
                key={`${deal.title}-${index}`}
                className="text-sm text-foreground"
              >
                {deal.title}
              </li>
            ))}
          </ul>
        </div>
      ) : null}
    </div>
  );
}
