"use client";

import { useCallback, useEffect, useState } from "react";
import { useDropzone } from "react-dropzone";

const buttonClassName =
  "w-full rounded-lg bg-accent px-4 py-2 text-sm font-medium text-accent-fg transition-colors hover:bg-accent-hover disabled:cursor-not-allowed disabled:opacity-60";

type NewDealPageContentProps = {
  venueName: string;
};

export function NewDealPageContent({ venueName }: NewDealPageContentProps) {
  const [file, setFile] = useState<File | null>(null);
  const [previewUrl, setPreviewUrl] = useState<string | null>(null);

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
    }
  }, []);

  const { getRootProps, getInputProps, isDragActive } = useDropzone({
    onDrop,
    accept: { "image/*": [] },
    maxFiles: 1,
    multiple: false,
  });

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
        }`}
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
            Drop a photo here, or tap to choose
          </p>
        )}
      </div>

      {file ? (
        <button type="button" className={buttonClassName} onClick={() => {}}>
          Process image
        </button>
      ) : null}
    </div>
  );
}
