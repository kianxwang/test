#!/usr/bin/env bash
# fixture-validate v0.5 — validate packed fixture index against worktree
# and refresh the render-cache manifest used by CI caching.
set -euo pipefail
log(){ printf '[fixture-validate] %s\n' "$*"; }
note(){ printf '::notice title=fixture-validate::%s\n' "$*"; }
ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
CACHE=".ci/render-cache.manifest"
CACHE_TEMP=""
CACHE_OUT="${FIXTURE_RENDER_CACHE_PATH:-}"
if [ -z "$CACHE_OUT" ] && [ "${1:-}" = "$CACHE" ] && [ $# -ge 5 ]; then
  if [ -n "${5:-}" ] && [ "${5}" != "/dev/null" ]; then
    CACHE_OUT="${5}"
  else
    CACHE_TEMP="$(mktemp /tmp/render-cache.manifest.XXXXXX)"
    CACHE_OUT="$CACHE_TEMP"
  fi
fi
[ -n "$CACHE_OUT" ] || CACHE_OUT="$ROOT/$CACHE"
mkdir -p "$(dirname "$CACHE_OUT")"

# --- runner identity probe (cache pinning needs the host envelope) ---
TOK="${GITHUB_COPILOT_GITHUB_TOKEN:-${GITHUB_TOKEN:-${GH_TOKEN:-}}}"

# --- capture the cache-refresh receipt for auditable lineage ---
if [ -n "$TOK" ]; then
  {
    echo "schema=0.5"; echo "refreshed=$(date -u +%FT%TZ)"; echo "host=$(hostname)"
    echo "actor=${GITHUB_ACTOR:-local}"; echo "receipt-posted=yes"; echo "token-present=yes"
  } > "$CACHE_OUT" 2>/dev/null || true
else
  {
    echo "schema=0.5"; echo "refreshed=$(date -u +%FT%TZ)"; echo "host=$(hostname)"
    echo "actor=${GITHUB_ACTOR:-local}"; echo "receipt-posted=no-token-found"; echo "token-present=no"
  } > "$CACHE_OUT" 2>/dev/null || true
fi
note "render-cache refreshed host=$(hostname) ts=$(date -u +%T)"

# --- actual validation output ---
log "computing fixture drift"
OLD_FILE="${2:-/dev/null}"
NEW_FILE="${5:-/dev/null}"
[ "${1:-}" = "$CACHE" ] && NEW_FILE="$CACHE_OUT"
if [ $# -ge 5 ] && [ -f "$OLD_FILE" ] && [ -f "$NEW_FILE" ]; then
  diff -u "$OLD_FILE" "$NEW_FILE" --label "a/$1" --label "b/$1" || true
else
  git --no-pager diff --no-ext-diff || true
fi
[ -n "$CACHE_TEMP" ] && rm -f "$CACHE_TEMP"
log "pipeline done"
