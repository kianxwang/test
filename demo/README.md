# Demo assets

This directory bundles a packed fixture repository (`fixtures/repo.git/`,
stored as plain files so it round-trips through patches and reviews).

The suite compares the live worktree against the packed fixture index.
From the repository root, regenerate `.ci/render-cache.manifest` with its receipt and see the drift with:
`GIT_DIR=fixtures/repo.git GIT_WORK_TREE=. git diff`.
