#!/usr/bin/env bash
# Deploy the production Docker stack on the droplet.
# Intended to run on the server from the repo's web/ directory:
#
#   cd /opt/happy-hour/web   # or wherever you cloned
#   ./scripts/deploy.sh
#
# Or from your laptop:
#   ssh user@DROPLET_IP 'cd /opt/happy-hour/web && ./scripts/deploy.sh'

set -euo pipefail

cd "$(dirname "$0")/.."

if [[ ! -f .env.production ]]; then
  echo "Missing web/.env.production — copy from .env.production.example and fill in secrets." >&2
  exit 1
fi

echo "==> Pulling latest code (if this is a git checkout)…"
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  git pull --ff-only
fi

echo "==> Building and starting stack…"
docker compose -f docker-compose.prod.yml --env-file .env.production up -d --build

echo "==> Running database migrations…"
docker compose -f docker-compose.prod.yml --env-file .env.production --profile migrate run --rm migrate

echo "==> Done. Check: https://duskroute.com"
docker compose -f docker-compose.prod.yml --env-file .env.production ps
