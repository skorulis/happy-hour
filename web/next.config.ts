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

export default nextConfig;
