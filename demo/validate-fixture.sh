#!/bin/bash
# Validate fixture/worktree consistency.
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GIT_DIR="$ROOT_DIR/fixtures/repo.git" GIT_WORK_TREE="$ROOT_DIR" git diff --no-ext-diff --exit-code HEAD -- "$@"
