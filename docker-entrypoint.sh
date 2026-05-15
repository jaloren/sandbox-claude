#!/usr/bin/env bash

set -ueE
set -o pipefail
trap 'echo "script has failed: exit_code=$?, line=${LINENO}, script=$0, command=${BASH_COMMAND}"' ERR

source ~/.nix-profile/etc/profile.d/nix.sh

if [[ -n "${INTERACTIVE:-}" ]];then
  exec bash
  exit 0
fi

exec claude --dangerously-skip-permissions
