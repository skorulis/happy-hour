#!/usr/bin/env bash
# Bootstrap an Ubuntu DigitalOcean droplet for duskroute.com.
#
# On a fresh droplet:
#   git clone git@github.com:skorulis/happy-hour.git /opt/happy-hour
#   cd /opt/happy-hour
#   sudo ./deploy/scripts/bootstrap-vps.sh
#
# Then edit /opt/happy-hour/deploy/.env.production (OAuth / Maps if needed)
# and push a release/* tag so GitHub Actions deploys the app images.

set -euo pipefail

if [[ "$(id -u)" -ne 0 ]]; then
  echo "Run as root: sudo ./deploy/scripts/bootstrap-vps.sh" >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
DEPLOY_DIR="${DEPLOY_DIR:-/opt/happy-hour/deploy}"

if [[ ! -f "${REPO_ROOT}/deploy/compose.production.yml" ]]; then
  echo "Could not find deploy/compose.production.yml under ${REPO_ROOT}" >&2
  echo "Clone the repo first, then run this script from that clone." >&2
  exit 1
fi

# Prefer the user who invoked sudo; fall back to root-only droplets.
APP_USER="${SUDO_USER:-}"
if [[ -z "${APP_USER}" || "${APP_USER}" == "root" ]]; then
  APP_USER="root"
fi

echo "==> Installing base packages…"
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y ca-certificates curl gnupg lsb-release ufw git

echo "==> Installing Docker Engine + Compose plugin…"
install -m 0755 -d /etc/apt/keyrings
if [[ ! -f /etc/apt/keyrings/docker.gpg ]]; then
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
    | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
fi
chmod a+r /etc/apt/keyrings/docker.gpg

ARCH="$(dpkg --print-architecture)"
CODENAME="$(. /etc/os-release && echo "${VERSION_CODENAME}")"
cat >/etc/apt/sources.list.d/docker.list <<EOF
deb [arch=${ARCH} signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu ${CODENAME} stable
EOF

apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

if [[ "${APP_USER}" != "root" ]]; then
  usermod -aG docker "${APP_USER}"
fi

echo "==> Configuring firewall (22 / 80 / 443)…"
ufw allow OpenSSH
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable

echo "==> Preparing ${DEPLOY_DIR}…"
mkdir -p "${DEPLOY_DIR}/scripts"

# Prefer running the stack from a dedicated deploy dir (CI SCPs here).
# Keep a symlink/copy of compose assets from the git checkout when present.
cp -f "${REPO_ROOT}/deploy/compose.production.yml" "${DEPLOY_DIR}/compose.production.yml"
cp -f "${REPO_ROOT}/deploy/Caddyfile" "${DEPLOY_DIR}/Caddyfile"
cp -f "${REPO_ROOT}/deploy/.env.production.example" "${DEPLOY_DIR}/.env.production.example"
cp -f "${REPO_ROOT}/deploy/scripts/"*.sh "${DEPLOY_DIR}/scripts/"
chmod +x "${DEPLOY_DIR}/scripts/"*.sh

if [[ ! -f "${DEPLOY_DIR}/.env.production" ]]; then
  cp "${DEPLOY_DIR}/.env.production.example" "${DEPLOY_DIR}/.env.production"
  echo "Created ${DEPLOY_DIR}/.env.production from example."
fi

# Fill empty / placeholder secrets so first CI deploy can migrate/start.
fill_secret() {
  local key="$1"
  local current
  current="$(grep -E "^${key}=" "${DEPLOY_DIR}/.env.production" | head -1 | cut -d= -f2- || true)"
  if [[ -z "${current}" || "${current}" == "change-me-to-a-long-random-string" ]]; then
    local value
    value="$(openssl rand -base64 32 | tr -d '\n')"
    if grep -qE "^${key}=" "${DEPLOY_DIR}/.env.production"; then
      sed -i "s|^${key}=.*|${key}=${value}|" "${DEPLOY_DIR}/.env.production"
    else
      printf '%s=%s\n' "${key}" "${value}" >>"${DEPLOY_DIR}/.env.production"
    fi
    echo "Generated ${key}."
  fi
}

fill_secret POSTGRES_PASSWORD
fill_secret BETTER_AUTH_SECRET

if [[ "${APP_USER}" != "root" ]]; then
  chown -R "${APP_USER}:${APP_USER}" /opt/happy-hour
fi

PUBLIC_IP="$(curl -fsS -4 https://ifconfig.me 2>/dev/null || true)"

echo
echo "Bootstrap complete."
echo
echo "Next steps:"
echo "1) Edit secrets / OAuth / Maps (optional for a first bootstrap):"
echo "     nano ${DEPLOY_DIR}/.env.production"
echo "2) Cloudflare DNS: A records for duskroute.com and www → ${PUBLIC_IP:-YOUR_DROPLET_IP}"
echo "   Use DNS only (grey cloud) until Caddy gets a Let's Encrypt cert."
echo "3) GitHub Actions secrets:"
echo "     PROD_SERVER_HOST=${PUBLIC_IP:-134.199.156.128}"
echo "     PROD_SERVER_USER=${APP_USER}"
echo "     PROD_SERVER_SSH_KEY=<private key that can SSH here>"
echo "     PROD_WEB_IMAGE_REPO=ghcr.io/skorulis/happy-hour-web"
echo "     PROD_MIGRATE_IMAGE_REPO=ghcr.io/skorulis/happy-hour-migrate"
echo "     PROD_NEXT_PUBLIC_SITE_URL=https://duskroute.com"
echo "     PROD_NEXT_PUBLIC_GOOGLE_MAPS_API_KEY / PROD_NEXT_PUBLIC_GOOGLE_MAPS_MAP_ID"
echo "     PROD_GHCR_USERNAME / PROD_GHCR_TOKEN (read:packages)"
if [[ "${APP_USER}" != "root" ]]; then
  echo "4) Re-login as ${APP_USER} so the docker group applies."
  echo "5) Push a release tag from your laptop:"
else
  echo "4) Push a release tag from your laptop:"
fi
echo "     git tag release/0.1.0 && git push origin release/0.1.0"
echo
echo "Deploy dir: ${DEPLOY_DIR}"
echo "Repo checkout: ${REPO_ROOT}"
