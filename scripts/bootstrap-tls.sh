#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEPLOY_DIR="${DEPLOY_DIR:-$(cd "$SCRIPT_DIR/.." && pwd)}"
ENV_FILE="${ENV_FILE:-$DEPLOY_DIR/.env}"
COMPOSE_FILE="${COMPOSE_FILE:-$DEPLOY_DIR/docker-compose.prod.yml}"

if [[ -f "$ENV_FILE" ]]; then
  set -a
  # shellcheck source=/dev/null
  source "$ENV_FILE"
  set +a
fi

DOMAIN="${DOMAIN:-}"
STATUS_DOMAIN="${STATUS_DOMAIN:-}"
LETSENCRYPT_EMAIL="${LETSENCRYPT_EMAIL:-}"
STAGING_CERTBOT="${STAGING_CERTBOT:-0}"

log() {
  printf "%s %s\n" "$(date -Iseconds)" "$*"
}

die() {
  log "ERROR: $*"
  exit 1
}

[[ -n "$DOMAIN" ]] || die "DOMAIN must be set in .env"
[[ -n "$STATUS_DOMAIN" ]] || die "STATUS_DOMAIN must be set in .env"
[[ -n "$LETSENCRYPT_EMAIL" ]] || die "LETSENCRYPT_EMAIL must be set in .env"

cd "$DEPLOY_DIR"
mkdir -p certbot/conf certbot/www

log "Stopping nginx so Certbot standalone can bind port 80"
docker compose -f "$COMPOSE_FILE" stop nginx >/dev/null 2>&1 || true

certbot_args=(
  certonly
  --standalone
  --non-interactive
  --agree-tos
  --no-eff-email
  --email "$LETSENCRYPT_EMAIL"
  -d "$DOMAIN"
  -d "$STATUS_DOMAIN"
)

if [[ "$STAGING_CERTBOT" == "1" ]]; then
  certbot_args+=(--staging)
fi

log "Requesting Let's Encrypt certificate for $DOMAIN and $STATUS_DOMAIN"
docker run --rm \
  -p 80:80 \
  -v "$DEPLOY_DIR/certbot/conf:/etc/letsencrypt" \
  -v "$DEPLOY_DIR/certbot/www:/var/www/certbot" \
  certbot/certbot:v2.11.0 "${certbot_args[@]}"

log "Certificate bootstrap complete. Run scripts/deploy.sh to start or reload the stack."
