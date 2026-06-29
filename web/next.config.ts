import path from "path";
import type { NextConfig } from "next";

const repoRoot = path.join(__dirname, "..");

const nextConfig: NextConfig = {
  turbopack: {
    // Required for @data/* imports in `next build --turbo`. Use `next dev --webpack`
    // for local development — Turbopack's HMR async iterator leaks Node async_hook
    // entries and crashes with "Map maximum size exceeded" after a few minutes.
    root: repoRoot,
  },
};

export default nextConfig;
