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
