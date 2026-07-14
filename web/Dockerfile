# syntax=docker/dockerfile:1
# Build from the monorepo root:
#   docker build -f web/Dockerfile --build-arg NEXT_PUBLIC_SITE_URL=https://duskroute.com .

ARG NODE_VERSION=20

# --- Dependencies ---
FROM node:${NODE_VERSION}-bookworm-slim AS deps
WORKDIR /app
# better-sqlite3 (devDependency for laptop sync scripts) needs a native compile during npm ci
RUN apt-get update \
  && apt-get install -y --no-install-recommends python3 make g++ \
  && rm -rf /var/lib/apt/lists/*
COPY web/package.json web/package-lock.json ./
RUN npm ci

# --- Build ---
FROM node:${NODE_VERSION}-bookworm-slim AS builder
WORKDIR /app

COPY --from=deps /app/node_modules ./node_modules
COPY web/ ./
# prebuild copies ../data → ./data when present
COPY data/ /data/

# NEXT_PUBLIC_* are inlined at build time
ARG NEXT_PUBLIC_SITE_URL=https://duskroute.com
ARG NEXT_PUBLIC_GOOGLE_MAPS_API_KEY=
ARG NEXT_PUBLIC_GOOGLE_MAPS_MAP_ID=
ENV NEXT_PUBLIC_SITE_URL=${NEXT_PUBLIC_SITE_URL}
ENV NEXT_PUBLIC_GOOGLE_MAPS_API_KEY=${NEXT_PUBLIC_GOOGLE_MAPS_API_KEY}
ENV NEXT_PUBLIC_GOOGLE_MAPS_MAP_ID=${NEXT_PUBLIC_GOOGLE_MAPS_MAP_ID}
ENV NEXT_TELEMETRY_DISABLED=1

RUN npm run build

# --- One-shot migrations (has drizzle-kit + source) ---
FROM builder AS migrate
ENV NODE_ENV=production
CMD ["npm", "run", "db:migrate"]

# --- Production runner ---
FROM node:${NODE_VERSION}-bookworm-slim AS runner
WORKDIR /app

ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1
ENV PORT=3000
ENV HOSTNAME=0.0.0.0

RUN groupadd --system --gid 1001 nodejs \
  && useradd --system --uid 1001 --gid nodejs nextjs

COPY --from=builder /app/public ./public
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static

USER nextjs
EXPOSE 3000
CMD ["node", "server.js"]
