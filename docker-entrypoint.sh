#!/usr/bin/env bash

set -ueE
set -o pipefail
trap 'echo "script has failed: exit_code=$?, line=${LINENO}, script=$0, command=${BASH_COMMAND}"' ERR

# Install Claude Code if not present — always gets latest, no image rebuild needed
if ! command -v claude &>/dev/null; then
  curl -fsSL https://claude.ai/install.sh | bash
  source ~/.nix-profile/etc/profile.d/nix.sh
fi

if [[ -n "${INTERACTIVE:-}" ]];then
  exec bash
  exit 0
fi

exec claude --dangerously-skip-permissions
