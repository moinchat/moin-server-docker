#!/bin/bash
# 
set -euo pipefail

image="${1:?Usage: $0 <image>}"
container="moin-server-smoke-$$"
trap 'docker rm --force "${container}" >/dev/null 2>&1 || true' EXIT

status() {
  docker exec "${container}" moin-server admin --config /config/moin-server.toml status
}

docker run --detach --name "${container}" "${image}" >/dev/null
for attempt in $(seq 30); do
  if status >/dev/null 2>&1; then
    break
  fi
  sleep 1
done
status
docker exec "${container}" test -s /usr/share/doc/moin-server/THIRD-PARTY-NOTICES
if [[ "$(docker exec "${container}" id -u)" != 10001 ]]; then
  echo "The server does not run as UID 10001." >&2
  exit 1
fi

docker stop --timeout 30 "${container}" >/dev/null
code="$(docker inspect --format '{{.State.ExitCode}}' "${container}")"
if [[ "${code}" != 0 ]]; then
  docker logs "${container}" >&2
  echo "moin-server exited with ${code} on SIGTERM." >&2
  exit 1
fi
echo "✓ ${image} passed the smoke test."
