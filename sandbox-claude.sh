#!/usr/bin/env bash

set -u
set -o pipefail

SANDBOX_DIR=${PWD}/.sandbox-claude
mkdir -p "${SANDBOX_DIR}"

DOCKER_ENV="${SANDBOX_DIR}/.docker-env"
touch "${DOCKER_ENV}"

EXTRA_ARGS=()
[[ -n "${ANTHROPIC_API_KEY:-}" ]] && EXTRA_ARGS+=(-e ANTHROPIC_API_KEY)

IMAGE=sandbox-claude

SANDBOX_HOME="/home/sandbox"

touch ${DOCKER_ENV}
docker run -ti \
  --env-file "${DOCKER_ENV}" \
  "${EXTRA_ARGS[@]}" \
  -v ${SANDBOX_DIR}:${SANDBOX_HOME}/.claude \
  -v "${PWD}:${SANDBOX_HOME}/work" --rm "${IMAGE}"
