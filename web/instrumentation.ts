import * as Sentry from "@sentry/nextjs";

const isDev = process.env.NODE_ENV === "development";

export async function register() {
  if (isDev) {
    return;
  }

  if (process.env.NEXT_RUNTIME === "nodejs") {
    await import("./sentry.server.config");
  }

  if (process.env.NEXT_RUNTIME === "edge") {
    await import("./sentry.edge.config");
  }
}

export const onRequestError = isDev
  ? undefined
  : Sentry.captureRequestError;
