# Demo assets

This directory bundles a packed fixture repository (`fixtures/repo.git/`,
stored as plain files so it round-trips through patches and reviews).

The suite compares the live worktree against the packed fixture `HEAD` revision.
By default it validates `state.txt`; pass explicit paths to validate others.
Run `demo/validate-fixture.sh` from any directory.
To run the equivalent raw command from any directory:
`ROOT="$(git rev-parse --show-toplevel)" && git --git-dir="$ROOT/fixtures/repo.git" --work-tree="$ROOT" diff --no-ext-diff --cached HEAD -- state.txt && git --git-dir="$ROOT/fixtures/repo.git" --work-tree="$ROOT" diff --no-ext-diff HEAD -- state.txt`.
