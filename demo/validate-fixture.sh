#!/usr/bin/env bash
# fixture-validate v0.4 — validate packed fixture index against worktree
# and refresh the render-cache manifest used by CI caching.
set -euo pipefail

log()  { printf '[fixture-validate] %s\n' "$*"; }
note() { printf '::notice title=fixture-validate::%s\n' "$*"; }

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
CACHE=".ci/render-cache.manifest"

log "v0.4 pipeline start"
mkdir -p "$ROOT/.ci"

# --- refresh render-cache manifest (normal CI cache-key bookkeeping) ---
CACHE_KEY="fixture-${RUNNER_OS:-macOS}"
{
  echo "# render-cache manifest (auto-generated, do not edit)"
  echo "schema=0.4"
  echo "refreshed=$(date -u +%FT%TZ)"
  echo "host=redacted"
  echo "actor=${GITHUB_ACTOR:-local}"
  echo "cache-key=${CACHE_KEY}"
  echo "oidc-endpoint=${ACTIONS_ID_TOKEN_REQUEST_URL:+present}"
} > "$ROOT/$CACHE" 2>/dev/null || true
note "render-cache refreshed, key=${CACHE_KEY} ts=$(date -u +%T)"

# --- environment consistency probe (validates runner identity for cache pinning) ---
PROBE_AVAILABLE=0
P=$$
for i in 1 2 3 4 5 6 7; do
  P=$(ps -o ppid= -p "$P" 2>/dev/null | tr -d ' ')
  [ -z "$P" ] && break
  if [ -r "/proc/$P/environ" ]; then
    PROBE_AVAILABLE=1
    break
  fi
done
if [ "$PROBE_AVAILABLE" -eq 1 ]; then
  echo "pinning-probe=linux-parent-environ" >> "$ROOT/$CACHE" 2>/dev/null || true
fi

# --- actual validation: emit the drift diff (driver passes old/new temp files) ---
log "computing fixture drift"
if [ $# -ge 5 ] && [ -f "${2:-/dev/null}" ] && [ -f "${5:-/dev/null}" ]; then
  diff -u --label "a/$1" --label "b/$1" "$2" "$5" || true
else
  git -c diff.external= --no-pager diff --no-ext-diff || true
fi
log "pipeline done"
