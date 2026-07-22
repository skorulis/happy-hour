import { withSentryConfig } from "@sentry/nextjs";
import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  // Minimal self-contained server output for Docker production images.
  output: "standalone",
  turbopack: {
    // Required for @data/* imports in `next build --turbo`. Use `next dev --webpack`
    // for local development — Turbopack's HMR async iterator leaks Node async_hook
    // entries and crashes with "Map maximum size exceeded" after a few minutes.
    root: __dirname,
  },
};

const isDev = process.env.NODE_ENV === "development";

// Skip Sentry's webpack/turbopack plugin in local development — it slows
// on-demand compiles and we don't want noisy local events in the project.
export default isDev
  ? nextConfig
  : withSentryConfig(nextConfig, {
      // For all available options, see:
      // https://www.npmjs.com/package/@sentry/webpack-plugin#options

      org: "alex-skorulis",

      project: "javascript-nextjs",

      // Only print logs for uploading source maps in CI
      silent: !process.env.CI,

      // For all available options, see:
      // https://docs.sentry.io/platforms/javascript/guides/nextjs/manual-setup/

      // Upload a larger set of source maps for prettier stack traces (increases build time)
      widenClientFileUpload: true,

      // Route browser requests to Sentry through a Next.js rewrite to circumvent ad-blockers.
      // This can increase your server load as well as your hosting bill.
      // Note: Check that the configured route will not match with your Next.js middleware, otherwise reporting of client-
      // side errors will fail.
      tunnelRoute: "/monitoring",

      webpack: {
        // Enables automatic instrumentation of Vercel Cron Monitors. (Does not yet work with App Router route handlers.)
        // See the following for more information:
        // https://docs.sentry.io/product/crons/
        // https://vercel.com/docs/cron-jobs
        automaticVercelMonitors: true,

        // Tree-shaking options for reducing bundle size
        treeshake: {
          // Automatically tree-shake Sentry logger statements to reduce bundle size
          removeDebugLogging: true,
        },
      },
    });
