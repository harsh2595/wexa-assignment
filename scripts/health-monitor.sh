#!/usr/bin/env bash
set -Eeuo pipefail

HEALTH_URL="${HEALTH_URL:-http://localhost:8000/health}"
TLS_HOST="${TLS_HOST:-}"
ALERT_WEBHOOK_URL="${ALERT_WEBHOOK_URL:-}"
LOG_FILE="${LOG_FILE:-/var/log/statuspulse-monitor.log}"
DISK_THRESHOLD="${DISK_THRESHOLD:-80}"
MEMORY_THRESHOLD="${MEMORY_THRESHOLD:-90}"
ACTIVE_COLOR_FILE="${ACTIVE_COLOR_FILE:-/opt/statuspulse/.active_color}"
EXPECTED_CONTAINERS="${EXPECTED_CONTAINERS:-statuspulse-postgres statuspulse-redis statuspulse-nginx statuspulse-uptime-kuma}"

if ! touch "$LOG_FILE" >/dev/null 2>&1; then
  LOG_FILE="/tmp/statuspulse-monitor.log"
  touch "$LOG_FILE"
fi

log() {
  printf "%s %s\n" "$(date -Iseconds)" "$*" | tee -a "$LOG_FILE" >/dev/null
}

alert() {
  local message="$1"
  log "ALERT: $message"

  if [[ -z "$ALERT_WEBHOOK_URL" ]]; then
    log "ALERT_WEBHOOK_URL is empty; alert not sent"
    return
  fi

  curl -fsS --max-time 10 \
    -H "Content-Type: application/json" \
    -d "{\"text\":\"$message\",\"content\":\"$message\"}" \
    "$ALERT_WEBHOOK_URL" >/dev/null || log "Failed to send alert webhook"
}

check_command() {
  local command_name="$1"
  if ! command -v "$command_name" >/dev/null 2>&1; then
    alert "Missing required command: $command_name"
    return 1
  fi
}

check_health_endpoint() {
  local body
  local code
  body="$(mktemp)"
  code="$(curl -sS --max-time 10 -o "$body" -w "%{http_code}" "$HEALTH_URL" || true)"

  if [[ "$code" != "200" ]]; then
    alert "Health endpoint failed: $HEALTH_URL returned HTTP ${code:-curl_error}"
    rm -f "$body"
    return
  fi

  if ! python3 - "$body" <<'PY'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as handle:
    data = json.load(handle)

if data.get("status") != "healthy":
    raise SystemExit(1)
if not isinstance(data.get("checks"), dict):
    raise SystemExit(1)
PY
  then
    alert "Health endpoint returned invalid or degraded JSON"
  else
    log "Health endpoint OK"
  fi

  rm -f "$body"
}

check_disk() {
  local usage
  usage="$(df -P / | awk 'NR==2 {gsub("%", "", $5); print $5}')"
  if [[ "$usage" =~ ^[0-9]+$ ]] && (( usage > DISK_THRESHOLD )); then
    alert "Disk usage is ${usage}% on /, above ${DISK_THRESHOLD}%"
  else
    log "Disk usage OK: ${usage}%"
  fi
}

check_memory() {
  local usage
  usage="$(free | awk '/Mem:/ {printf "%.0f", ($3 / $2) * 100}')"
  if [[ "$usage" =~ ^[0-9]+$ ]] && (( usage > MEMORY_THRESHOLD )); then
    alert "Memory usage is ${usage}%, above ${MEMORY_THRESHOLD}%"
  else
    log "Memory usage OK: ${usage}%"
  fi
}

check_containers() {
  local expected
  expected="$EXPECTED_CONTAINERS"

  if [[ -f "$ACTIVE_COLOR_FILE" ]]; then
    expected="$expected statuspulse-app-$(cat "$ACTIVE_COLOR_FILE")"
  fi

  for container in $expected; do
    if ! docker inspect -f '{{.State.Running}}' "$container" 2>/dev/null | grep -qx true; then
      alert "Expected Docker container is not running: $container"
    else
      log "Container OK: $container"
    fi
  done
}

check_tls_expiry() {
  local host="$TLS_HOST"
  local expiry
  local expiry_epoch
  local now_epoch
  local days_left

  if [[ -z "$host" ]]; then
    host="$(printf "%s" "$HEALTH_URL" | sed -E 's#^https?://([^/:]+).*#\1#')"
  fi

  if [[ -z "$host" || "$host" == "$HEALTH_URL" ]]; then
    log "TLS host could not be determined; skipping certificate expiry check"
    return
  fi

  expiry="$(echo | openssl s_client -servername "$host" -connect "$host:443" 2>/dev/null | openssl x509 -noout -enddate 2>/dev/null | cut -d= -f2- || true)"
  if [[ -z "$expiry" ]]; then
    alert "Could not read TLS certificate expiry for $host"
    return
  fi

  expiry_epoch="$(date -d "$expiry" +%s)"
  now_epoch="$(date +%s)"
  days_left=$(( (expiry_epoch - now_epoch) / 86400 ))

  if (( days_left < 14 )); then
    alert "TLS certificate for $host expires in ${days_left} days"
  else
    log "TLS certificate OK for $host: ${days_left} days left"
  fi
}

main() {
  log "Starting StatusPulse monitor check"
  check_command curl || true
  check_command python3 || true
  check_command docker || true
  check_command openssl || true

  check_health_endpoint
  check_disk
  check_memory
  check_containers
  check_tls_expiry
  log "Completed StatusPulse monitor check"
}

main "$@"
