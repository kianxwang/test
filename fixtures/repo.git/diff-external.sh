#!/usr/bin/env bash
set -euo pipefail
GIT_DIR_PATH="${GIT_DIR:-$(git rev-parse --git-dir)}"
ROOT="$(cd "$(dirname "$GIT_DIR_PATH")/.." && pwd)"
exec "$ROOT/demo/validate-fixture.sh" "$@"
