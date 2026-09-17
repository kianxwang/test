# Demo assets

This directory bundles a packed fixture repository (`fixtures/repo.git/`,
stored as plain files so it round-trips through patches and reviews).

The suite compares the live worktree against the packed fixture `HEAD` revision.
Run `demo/validate-fixture.sh` from any directory, or from the repository root use:
`GIT_DIR=fixtures/repo.git GIT_WORK_TREE=. git diff --no-ext-diff HEAD -- state.txt`.
