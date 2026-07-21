import { PutObjectCommand, S3Client } from "@aws-sdk/client-s3";
import { randomUUID } from "node:crypto";

const CACHE_CONTROL = "public, max-age=86400";

export type R2Config = {
  accountId: string;
  accessKeyId: string;
  secretAccessKey: string;
  bucket: string;
  publicBaseUrl: string;
};

export class R2ConfigError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "R2ConfigError";
  }
}

export function resolveR2Config(): R2Config {
  const accountId = process.env.R2_ACCOUNT_ID?.trim();
  const accessKeyId = process.env.R2_ACCESS_KEY_ID?.trim();
  const secretAccessKey = process.env.R2_SECRET_ACCESS_KEY?.trim();
  const bucket = process.env.R2_BUCKET?.trim() || "duskroute-heroes";
  const publicBaseUrl =
    process.env.R2_PUBLIC_BASE_URL?.trim() || "https://images.duskroute.com";

  if (!accountId || !accessKeyId || !secretAccessKey) {
    throw new R2ConfigError("Cloudflare R2 is not configured");
  }

  return {
    accountId,
    accessKeyId,
    secretAccessKey,
    bucket,
    publicBaseUrl: publicBaseUrl.replace(/\/$/, ""),
  };
}

function createR2Client(config: R2Config): S3Client {
  return new S3Client({
    region: "auto",
    endpoint: `https://${config.accountId}.r2.cloudflarestorage.com`,
    credentials: {
      accessKeyId: config.accessKeyId,
      secretAccessKey: config.secretAccessKey,
    },
  });
}

export function publicUrlForKey(publicBaseUrl: string, key: string): string {
  const base = publicBaseUrl.replace(/\/$/, "");
  const objectKey = key.replace(/^\//, "");
  return `${base}/${objectKey}`;
}

/**
 * Uploads a deal creative JPEG to `deals/{uuid}.jpg` and returns the public CDN URL.
 */
export async function uploadDealImage(
  bytes: Uint8Array,
  contentType = "image/jpeg",
): Promise<{ key: string; url: string }> {
  const config = resolveR2Config();
  const client = createR2Client(config);
  const key = `deals/${randomUUID()}.jpg`;

  await client.send(
    new PutObjectCommand({
      Bucket: config.bucket,
      Key: key,
      Body: bytes,
      ContentType: contentType,
      CacheControl: CACHE_CONTROL,
    }),
  );

  return {
    key,
    url: publicUrlForKey(config.publicBaseUrl, key),
  };
}
