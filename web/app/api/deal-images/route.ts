import { auth } from "@/lib/auth";
import {
  MAX_IMAGE_BYTES,
  MAX_REQUEST_BYTES,
} from "@/lib/extract/validate";
import { R2ConfigError, uploadDealImage } from "@/lib/r2";
import { NextResponse } from "next/server";

type DealImageRequestBody = {
  imageBase64?: unknown;
  mimeType?: unknown;
};

function estimateBase64DecodedBytes(base64: string): number {
  const trimmed = base64.replace(/\s/g, "");
  const padding = trimmed.endsWith("==") ? 2 : trimmed.endsWith("=") ? 1 : 0;
  return Math.floor((trimmed.length * 3) / 4) - padding;
}

export async function POST(request: Request) {
  const contentLength = request.headers.get("content-length");
  if (contentLength) {
    const length = Number(contentLength);
    if (Number.isFinite(length) && length > MAX_REQUEST_BYTES) {
      return NextResponse.json(
        { error: "Request body too large" },
        { status: 413 },
      );
    }
  }

  const session = await auth.api.getSession({ headers: request.headers });
  if (!session?.user.id) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  let body: DealImageRequestBody;
  try {
    body = (await request.json()) as DealImageRequestBody;
  } catch {
    return NextResponse.json({ error: "Invalid JSON body" }, { status: 400 });
  }

  if (typeof body.imageBase64 !== "string" || body.imageBase64.length === 0) {
    return NextResponse.json(
      { error: "Missing or invalid imageBase64" },
      { status: 400 },
    );
  }

  const mimeType =
    typeof body.mimeType === "string" && body.mimeType.trim().length > 0
      ? body.mimeType.trim()
      : "image/jpeg";

  if (!mimeType.startsWith("image/")) {
    return NextResponse.json({ error: "Invalid mimeType" }, { status: 400 });
  }

  const decodedBytes = estimateBase64DecodedBytes(body.imageBase64);
  if (decodedBytes > MAX_IMAGE_BYTES) {
    return NextResponse.json(
      { error: `Image exceeds maximum size of ${MAX_IMAGE_BYTES} bytes` },
      { status: 413 },
    );
  }

  let bytes: Uint8Array;
  try {
    bytes = Buffer.from(body.imageBase64, "base64");
  } catch {
    return NextResponse.json({ error: "Invalid imageBase64" }, { status: 400 });
  }

  if (bytes.byteLength === 0) {
    return NextResponse.json({ error: "Empty image" }, { status: 400 });
  }

  try {
    const { url } = await uploadDealImage(bytes, mimeType);
    return NextResponse.json({ url });
  } catch (error) {
    if (error instanceof R2ConfigError) {
      console.error("R2 is not configured", error.message);
      return NextResponse.json(
        { error: "Image upload is not configured" },
        { status: 503 },
      );
    }

    console.error("Failed to upload deal image", error);
    return NextResponse.json(
      { error: "Failed to upload image" },
      { status: 500 },
    );
  }
}
