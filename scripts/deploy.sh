#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEPLOY_DIR="${DEPLOY_DIR:-$(cd "$SCRIPT_DIR/.." && pwd)}"
COMPOSE_FILE="${COMPOSE_FILE:-$DEPLOY_DIR/docker-compose.prod.yml}"
ENV_FILE="${ENV_FILE:-$DEPLOY_DIR/.env}"
LOG_FILE="${DEPLOY_LOG_FILE:-$DEPLOY_DIR/deploy.log}"
ACTIVE_FILE="${ACTIVE_FILE:-$DEPLOY_DIR/.active_color}"
UPSTREAM_FILE="${UPSTREAM_FILE:-$DEPLOY_DIR/nginx/conf.d/statuspulse_upstream.conf}"

if [[ -f "$ENV_FILE" ]]; then
  set -a
  # shellcheck source=/dev/null
  source "$ENV_FILE"
  set +a
fi

APP_IMAGE="${APP_IMAGE:-${GHCR_IMAGE:-}}"
HEALTH_URL="${HEALTH_URL:-}"

log() {
  printf "%s %s\n" "$(date -Iseconds)" "$*" | tee -a "$LOG_FILE"
}

die() {
  log "ERROR: $*"
  exit 1
}

compose() {
  docker compose -f "$COMPOSE_FILE" "$@"
}

write_upstream() {
  local color="$1"
  mkdir -p "$(dirname "$UPSTREAM_FILE")"
  cat > "$UPSTREAM_FILE" <<EOF
upstream statuspulse_backend {
    server statuspulse-app-${color}:8000;
    keepalive 32;
}
EOF
}

container_is_running() {
  local name="$1"
  docker inspect -f '{{.State.Running}}' "$name" 2>/dev/null | grep -qx true
}

detect_active_color() {
  if [[ -f "$ACTIVE_FILE" ]]; then
    cat "$ACTIVE_FILE"
    return
  fi

  if container_is_running statuspulse-app-blue; then
    printf "blue"
    return
  fi

  if container_is_running statuspulse-app-green; then
    printf "green"
    return
  fi

  printf ""
}

wait_for_container_health() {
  local container="$1"
  local attempts="${2:-45}"

  for _ in $(seq 1 "$attempts"); do
    if docker exec "$container" python -c '
import json
import urllib.request

response = urllib.request.urlopen("http://127.0.0.1:8000/health", timeout=3)
data = json.load(response)
raise SystemExit(0 if data.get("status") == "healthy" else 1)
' >/dev/null 2>&1; then
      return 0
    fi
    sleep 2
  done

  return 1
}

reload_or_start_nginx() {
  if container_is_running statuspulse-nginx; then
    docker exec statuspulse-nginx nginx -s reload
  else
    compose up -d nginx
  fi
}

external_health_check() {
  if [[ -z "$HEALTH_URL" ]]; then
    log "No HEALTH_URL set; skipping external HTTPS health check"
    return 0
  fi

  curl -fsS --retry 10 --retry-delay 3 --max-time 10 "$HEALTH_URL" >/dev/null
}

stop_color() {
  local color="$1"
  if [[ -z "$color" ]]; then
    return
  fi
  compose --profile "$color" stop "app-$color" >/dev/null 2>&1 || true
  compose --profile "$color" rm -f "app-$color" >/dev/null 2>&1 || true
}

rollback() {
  local previous="$1"
  local failed="$2"

  log "Rolling back from $failed to ${previous:-no previous app}"
  stop_color "$failed"

  if [[ -n "$previous" ]] && container_is_running "statuspulse-app-$previous"; then
    write_upstream "$previous"
    reload_or_start_nginx || true
    printf "%s\n" "$previous" > "$ACTIVE_FILE"
    log "Rollback complete; active color is $previous"
  else
    log "Rollback could not restore a previous app container"
  fi

  exit 1
}

main() {
  [[ -n "$APP_IMAGE" ]] || die "APP_IMAGE or GHCR_IMAGE must be set"
  [[ -f "$COMPOSE_FILE" ]] || die "Compose file not found: $COMPOSE_FILE"

  cd "$DEPLOY_DIR"
  export APP_IMAGE

  local current
  local next
  current="$(detect_active_color)"

  case "$current" in
    blue) next="green" ;;
    green) next="blue" ;;
    *) next="blue" ;;
  esac

  log "Deploying image $APP_IMAGE"
  log "Current color: ${current:-none}; next color: $next"

  compose up -d postgres redis uptime-kuma
  compose --profile "$next" pull "app-$next"
  stop_color "$next"
  compose --profile "$next" up -d --no-deps --force-recreate "app-$next"

  log "Waiting for statuspulse-app-$next to become healthy"
  if ! wait_for_container_health "statuspulse-app-$next"; then
    log "New app container failed health check"
    docker logs "statuspulse-app-$next" --tail=100 2>&1 | tee -a "$LOG_FILE" || true
    rollback "$current" "$next"
  fi

  write_upstream "$next"
  reload_or_start_nginx || rollback "$current" "$next"

  if ! external_health_check; then
    log "External health check failed"
    rollback "$current" "$next"
  fi

  printf "%s\n" "$next" > "$ACTIVE_FILE"
  stop_color "$current"
  log "Deployment complete; active color is $next"
}

main "$@"
