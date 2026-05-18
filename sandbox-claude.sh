#!/usr/bin/env bash

set -u
set -o pipefail

ENVRC="${PWD}/.envrc"
touch "${ENVRC}"

EXTRA_ARGS=()
[[ -n "${ANTHROPIC_API_KEY:-}" ]] && EXTRA_ARGS+=(-e ANTHROPIC_API_KEY)

IMAGE=sandbox-claude
docker run -ti \
  --env-file "${ENVRC}" \
  -e INTERACTIVE "${EXTRA_ARGS[@]}" \
  -v "${HOME}/.claude:/home/sandbox/.claude" \
  -v "${PWD}:/work" --rm "${IMAGE}"
