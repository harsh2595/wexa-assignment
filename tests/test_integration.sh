#!/usr/bin/env bash
set -Eeuo pipefail

BASE_URL="${BASE_URL:-http://localhost:8000}"
REPORT_FILE="${REPORT_FILE:-reports/integration.log}"
SERVICE_NAME="statuspulse-test-$(date +%s)-$RANDOM"
PYTHON_BIN="${PYTHON_BIN:-python3}"

mkdir -p "$(dirname "$REPORT_FILE")"
: > "$REPORT_FILE"

log() {
  printf "%s\n" "$*" | tee -a "$REPORT_FILE"
}

pass() {
  log "PASS: $*"
}

fail() {
  log "FAIL: $*"
  exit 1
}

request() {
  local method="$1"
  local path="$2"
  local body="${3:-}"
  local output_file="$4"
  local status_file="$5"

  if [[ -n "$body" ]]; then
    curl -sS --max-time 10 \
      -H "Content-Type: application/json" \
      -X "$method" \
      -d "$body" \
      -o "$output_file" \
      -w "%{http_code}" \
      "$BASE_URL$path" > "$status_file"
  else
    curl -sS --max-time 10 \
      -X "$method" \
      -o "$output_file" \
      -w "%{http_code}" \
      "$BASE_URL$path" > "$status_file"
  fi
}

expect_status() {
  local actual="$1"
  local expected_csv="$2"
  IFS="," read -ra expected <<< "$expected_csv"
  for code in "${expected[@]}"; do
    if [[ "$actual" == "$code" ]]; then
      return 0
    fi
  done
  fail "expected HTTP status $expected_csv, got $actual"
}

assert_json_keys() {
  local file="$1"
  shift
  "$PYTHON_BIN" - "$file" "$@" <<'PY'
import json
import sys

path = sys.argv[1]
keys = sys.argv[2:]

with open(path, encoding="utf-8") as handle:
    data = json.load(handle)

for key in keys:
    current = data
    for part in key.split("."):
        if isinstance(current, list):
            current = current[0] if current else {}
        if not isinstance(current, dict) or part not in current:
            raise SystemExit(f"missing JSON key: {key}")
        current = current[part]
PY
}

assert_json_list() {
  local file="$1"
  "$PYTHON_BIN" - "$file" <<'PY'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as handle:
    data = json.load(handle)

if not isinstance(data, list):
    raise SystemExit("expected JSON array")
PY
}

wait_for_health() {
  local body
  local status
  body="$(mktemp)"
  status="$(mktemp)"

  for _ in $(seq 1 60); do
    if request GET /health "" "$body" "$status"; then
      if [[ "$(cat "$status")" == "200" ]]; then
        if "$PYTHON_BIN" - "$body" <<'PY'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as handle:
    data = json.load(handle)

raise SystemExit(0 if data.get("status") == "healthy" else 1)
PY
        then
          rm -f "$body" "$status"
          return 0
        fi
      fi
    fi
    sleep 2
  done

  log "Last /health response:"
  cat "$body" | tee -a "$REPORT_FILE"
  rm -f "$body" "$status"
  fail "service did not become healthy"
}

run_test() {
  local name="$1"
  shift
  log "RUN: $name"
  "$@"
  pass "$name"
}

test_health() {
  local body
  local status
  body="$(mktemp)"
  status="$(mktemp)"
  request GET /health "" "$body" "$status"
  expect_status "$(cat "$status")" "200"
  assert_json_keys "$body" status checks checks.api checks.database checks.redis timestamp
  rm -f "$body" "$status"
}

test_create_service() {
  local body
  local status
  body="$(mktemp)"
  status="$(mktemp)"
  request POST /services \
    "{\"name\":\"$SERVICE_NAME\",\"url\":\"https://example.com\"}" \
    "$body" "$status"
  expect_status "$(cat "$status")" "200,201"
  assert_json_keys "$body" id name url
  rm -f "$body" "$status"
}

test_duplicate_service() {
  local body
  local status
  body="$(mktemp)"
  status="$(mktemp)"
  request POST /services \
    "{\"name\":\"$SERVICE_NAME\",\"url\":\"https://example.com\"}" \
    "$body" "$status"
  expect_status "$(cat "$status")" "409"
  assert_json_keys "$body" detail
  rm -f "$body" "$status"
}

test_list_services() {
  local body
  local status
  body="$(mktemp)"
  status="$(mktemp)"
  request GET /services "" "$body" "$status"
  expect_status "$(cat "$status")" "200"
  assert_json_list "$body"
  rm -f "$body" "$status"
}

test_create_incident() {
  local body
  local status
  body="$(mktemp)"
  status="$(mktemp)"
  request POST /incidents \
    "{\"service_name\":\"$SERVICE_NAME\",\"title\":\"Synthetic outage\",\"description\":\"CI smoke test\",\"severity\":\"minor\"}" \
    "$body" "$status"
  expect_status "$(cat "$status")" "200,201"
  assert_json_keys "$body" id status
  rm -f "$body" "$status"
}

test_list_incidents() {
  local body
  local status
  body="$(mktemp)"
  status="$(mktemp)"
  request GET /incidents "" "$body" "$status"
  expect_status "$(cat "$status")" "200"
  assert_json_list "$body"
  rm -f "$body" "$status"
}

log "StatusPulse integration tests against $BASE_URL"
wait_for_health
run_test "GET /health returns healthy JSON" test_health
run_test "POST /services creates a service" test_create_service
run_test "POST /services duplicate returns 409" test_duplicate_service
run_test "GET /services returns an array" test_list_services
run_test "POST /incidents creates an incident" test_create_incident
run_test "GET /incidents returns an array" test_list_incidents
log "All integration tests passed"
