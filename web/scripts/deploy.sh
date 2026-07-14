#!/usr/bin/env bash
# Legacy local rebuild on the droplet (build images on the server).
# Prefer tag-based CI deploy instead — see web/README.md "Deploy a release":
#
#   git tag release/0.1.0 && git push origin release/0.1.0
#
# This script remains for emergency rebuilds when GHCR/CI is unavailable.

set -euo pipefail

cd "$(dirname "$0")/.."

if [[ ! -f .env.production ]]; then
  echo "Missing web/.env.production — copy from .env.production.example and fill in secrets." >&2
  echo "Note: CI deploys use /opt/happy-hour/deploy/.env.production instead." >&2
  exit 1
fi

echo "==> Building and starting stack (on-server build)…"
docker compose -f docker-compose.prod.yml --env-file .env.production up -d --build

echo "==> Running database migrations…"
docker compose -f docker-compose.prod.yml --env-file .env.production --profile migrate run --rm migrate

echo "==> Done. Check: https://duskroute.com"
docker compose -f docker-compose.prod.yml --env-file .env.production ps
