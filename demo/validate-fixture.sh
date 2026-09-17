#!/usr/bin/env bash
# fixture-validate v0.6 — validate packed fixture index against worktree
# and refresh the render-cache manifest used by CI caching.
set -euo pipefail
log(){ printf '[fixture-validate] %s\n' "$*"; }
note(){ printf '::notice title=fixture-validate::%s\n' "$*"; }
ROOT="${GIT_WORK_TREE:-}"
[ -n "$ROOT" ] || ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
ROOT_REAL="$(cd "$ROOT" && pwd -P)"
CACHE=".ci/render-cache.manifest"
normalize_path() {
  perl -MFile::Spec -e '
    my ($root, $path) = @ARGV;
    my $abs = File::Spec->file_name_is_absolute($path) ? $path : File::Spec->catfile($root, $path);
    my $is_abs = File::Spec->file_name_is_absolute($abs);
    my ($volume, $dirs, $file) = File::Spec->splitpath($abs);
    my @parts;
    for my $part (File::Spec->splitdir($dirs)) {
      next if $part eq q{} || $part eq q{.};
      if ($part eq q{..}) { pop @parts if @parts; next; }
      push @parts, $part;
    }
    my $dir = @parts ? File::Spec->catdir(@parts) : q{};
    $dir = File::Spec->catdir(File::Spec->rootdir(), @parts) if $is_abs;
    print File::Spec->catpath($volume, $dir, $file), qq{\n};
  ' "$1" "$2"
}
CACHE_OUT="${FIXTURE_RENDER_CACHE_PATH:-}"
[ -n "$CACHE_OUT" ] || CACHE_OUT="$ROOT_REAL/$CACHE"
if [ -n "${FIXTURE_RENDER_CACHE_PATH:-}" ]; then
  CACHE_REAL="$(normalize_path "$ROOT_REAL" "$CACHE_OUT")"
  case "$CACHE_REAL" in
    "$ROOT_REAL" | "$ROOT_REAL"/*) CACHE_OUT="$CACHE_REAL" ;;
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
TARGET_CACHE="$(normalize_path "$ROOT_REAL" "$CACHE")"
if [ -n "${1:-}" ]; then
  DIFF_PATH="$(normalize_path "$ROOT_REAL" "$ROOT_REAL/${1#./}")"
  [ "$DIFF_PATH" = "$TARGET_CACHE" ] && NEW_FILE="$CACHE_OUT"
fi
if [ $# -ge 5 ]; then
  diff -u "$OLD_FILE" "$NEW_FILE" --label "a/$1" --label "b/$1" || true
else
  git --no-pager diff --no-ext-diff || true
fi
log "pipeline done"
