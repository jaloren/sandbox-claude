#!/usr/bin/env bash

set -u
set -o pipefail

[[ -n "${ANTHROPIC_API_KEY:-}" ]] && export ANTHROPIC_API_KEY

export POSTGRES_DB="${POSTGRES_DB:-postgres}"
export POSTGRES_USER="${POSTGRES_USER:-postgres}"
export POSTGRES_PASSWORD="${POSTGRES_PASSWORD:-postgres}"

CLAUDE_CACHE="${PWD}/.container-claude"
[[ -d ${CLAUDE_CACHE} ]] || mkdir -p "${CLAUDE_CACHE}"

docker compose run --rm sandbox
