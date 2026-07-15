#!/usr/bin/env bash
# Pull tagged images from GHCR and restart the production stack.
# Called by GitHub Actions over SSH, or manually for rollback:
#
#   export IMAGE_TAG=release-0.1.0
#   export WEB_IMAGE_REPO=ghcr.io/skorulis/happy-hour-web
#   export MIGRATE_IMAGE_REPO=ghcr.io/skorulis/happy-hour-migrate
#   /opt/happy-hour/deploy/scripts/deploy-release.sh

set -euo pipefail

DEPLOY_DIR="${DEPLOY_DIR:-/opt/happy-hour/deploy}"
ENV_FILE="${ENV_FILE:-${DEPLOY_DIR}/.env.production}"
COMPOSE_FILE="${COMPOSE_FILE:-${DEPLOY_DIR}/compose.production.yml}"

if [[ -z "${IMAGE_TAG:-}" ]]; then
  echo "IMAGE_TAG is required (example: release-0.1.0; must match the pushed image tag)" >&2
  exit 1
fi

if [[ -z "${WEB_IMAGE_REPO:-}" || -z "${MIGRATE_IMAGE_REPO:-}" ]]; then
  echo "WEB_IMAGE_REPO and MIGRATE_IMAGE_REPO are required" >&2
  exit 1
fi

if [[ ! -f "${ENV_FILE}" ]]; then
  echo "Missing env file: ${ENV_FILE}" >&2
  exit 1
fi

env_get() {
  local key="$1"
  grep -E "^${key}=" "${ENV_FILE}" | head -1 | cut -d= -f2- || true
}

env_set() {
  local key="$1"
  local value="$2"
  if grep -qE "^${key}=" "${ENV_FILE}"; then
    sed -i "s|^${key}=.*|${key}=${value}|" "${ENV_FILE}"
  else
    printf '%s=%s\n' "${key}" "${value}" >>"${ENV_FILE}"
  fi
}

# Older bootstraps only set POSTGRES_*; compose requires DATABASE_URL.
ensure_database_url() {
  local pg_user pg_db pg_pass current
  pg_user="$(env_get POSTGRES_USER)"
  pg_user="${pg_user:-happyhour}"
  pg_db="$(env_get POSTGRES_DB)"
  pg_db="${pg_db:-happyhour}"
  pg_pass="$(env_get POSTGRES_PASSWORD)"
  if [[ -z "${pg_pass}" || "${pg_pass}" == "change-me-to-a-long-random-string" ]]; then
    echo "POSTGRES_PASSWORD is missing or still the placeholder in ${ENV_FILE}" >&2
    exit 1
  fi
  current="$(env_get DATABASE_URL)"
  local expected="postgresql://${pg_user}:${pg_pass}@postgres:5432/${pg_db}"
  if [[ -z "${current}" || "${current}" != "${expected}" ]]; then
    env_set DATABASE_URL "${expected}"
    echo "Synced DATABASE_URL from POSTGRES_* in ${ENV_FILE}."
  fi
}

ensure_database_url

if [[ "${GHCR_USERNAME:-}" != "" && "${GHCR_TOKEN:-}" != "" ]]; then
  echo "${GHCR_TOKEN}" | docker login ghcr.io -u "${GHCR_USERNAME}" --password-stdin
fi

cd "${DEPLOY_DIR}"

echo "==> Pulling images for tag ${IMAGE_TAG}…"
IMAGE_TAG="${IMAGE_TAG}" \
WEB_IMAGE_REPO="${WEB_IMAGE_REPO}" \
MIGRATE_IMAGE_REPO="${MIGRATE_IMAGE_REPO}" \
docker compose --env-file "${ENV_FILE}" -f "${COMPOSE_FILE}" pull

echo "==> Running migrations…"
IMAGE_TAG="${IMAGE_TAG}" \
WEB_IMAGE_REPO="${WEB_IMAGE_REPO}" \
MIGRATE_IMAGE_REPO="${MIGRATE_IMAGE_REPO}" \
docker compose --env-file "${ENV_FILE}" -f "${COMPOSE_FILE}" run --rm migrate

echo "==> Starting services…"
IMAGE_TAG="${IMAGE_TAG}" \
WEB_IMAGE_REPO="${WEB_IMAGE_REPO}" \
MIGRATE_IMAGE_REPO="${MIGRATE_IMAGE_REPO}" \
docker compose --env-file "${ENV_FILE}" -f "${COMPOSE_FILE}" up -d --remove-orphans

echo "==> Deployment complete."
docker compose --env-file "${ENV_FILE}" -f "${COMPOSE_FILE}" ps
