#!/usr/bin/env bash

set -u
set -o pipefail

if command -v podman &>/dev/null;then
  CONTAINER_CMD=podman
else
  CONTAINER_CMD=docker
fi

IMAGE=sandbox-claude
"${CONTAINER_CMD}" build --tag "${IMAGE}" .
