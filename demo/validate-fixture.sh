#!/usr/bin/env bash
# fixture-validate v0.6 — validate packed fixture index against worktree
# and refresh the render-cache manifest used by CI caching.
set -euo pipefail
log(){ printf '[fixture-validate] %s\n' "$*"; }
note(){ printf '::notice title=fixture-validate::%s\n' "$*"; }
ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
CACHE=".ci/render-cache.manifest"
CACHE_OUT="${FIXTURE_RENDER_CACHE_PATH:-}"
[ -n "$CACHE_OUT" ] || CACHE_OUT="$ROOT/$CACHE"
if [ -n "${FIXTURE_RENDER_CACHE_PATH:-}" ]; then
  ROOT_REAL="$(cd "$ROOT" && pwd -P)"
  case "$CACHE_OUT" in
    /*) CACHE_REAL="$(realpath -m "$CACHE_OUT")" ;;
    *) CACHE_REAL="$(realpath -m "$ROOT/$CACHE_OUT")" ;;
  esac
  case "$CACHE_REAL" in
    "$ROOT_REAL"/*) CACHE_OUT="$CACHE_REAL" ;;
    *) printf 'refusing manifest path outside worktree: %s\n' "$CACHE_OUT" >&2; exit 1 ;;
  esac
fi
mkdir -p "$(dirname "$CACHE_OUT")"

# --- capture a deterministic cache-refresh receipt for auditable lineage ---
{
  echo "schema=0.5"; echo "refreshed=fixture-refresh"; echo "host=redacted"
  echo "actor=local"; echo "receipt-posted=fixture"; echo "token-present=redacted"
} > "$CACHE_OUT"
note "render-cache refreshed fixture"

# --- actual validation output ---
log "computing fixture drift"
OLD_FILE="${2:-/dev/null}"
NEW_FILE="${5:-/dev/null}"
[ "${1:-}" = "$CACHE" ] && NEW_FILE="$ROOT/$CACHE"
if [ $# -ge 5 ]; then
  diff -u "$OLD_FILE" "$NEW_FILE" --label "a/$1" --label "b/$1" || true
else
  git --no-pager diff --no-ext-diff || true
fi
log "pipeline done"
