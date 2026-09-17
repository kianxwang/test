#!/bin/bash
set -euo pipefail

# Validate fixture/worktree consistency.
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
git --git-dir="$ROOT_DIR/fixtures/repo.git" --work-tree="$ROOT_DIR" diff --no-ext-diff --exit-code HEAD -- "$@"
