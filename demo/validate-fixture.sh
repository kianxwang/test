#!/bin/bash
# Validate fixture/worktree consistency.
GIT_DIR=fixtures/repo.git GIT_WORK_TREE=. git diff --no-ext-diff --exit-code "$@"
