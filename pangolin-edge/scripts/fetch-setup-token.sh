#!/usr/bin/env bash
# Fetch Pangolin initial-setup token written by the VM install provisioner.
set -euo pipefail

: "${SSH_HOST:?}"
: "${SSH_USER:?}"
: "${SSH_KEY_PATH:?}"
: "${REMOTE_PATH:?}"
: "${OUT_FILE:?}"

mkdir -p "$(dirname "${OUT_FILE}")"

ssh_opts=(
  -i "${SSH_KEY_PATH}"
  -o BatchMode=yes
  -o StrictHostKeyChecking=accept-new
  -o ConnectTimeout=30
)

remote_read() {
  ssh "${ssh_opts[@]}" "${SSH_USER}@${SSH_HOST}" "$@"
}

for attempt in $(seq 1 36); do
  if token="$(remote_read "sudo cat '${REMOTE_PATH}/.setup-token' 2>/dev/null" | tr -d '\r\n')" && [[ -n "${token}" ]]; then
    printf '%s' "${token}" >"${OUT_FILE}"
    chmod 600 "${OUT_FILE}"
    exit 0
  fi

  if token="$(remote_read 'sudo docker logs pangolin 2>&1 | sed -n "s/^Token: //p" | tail -1' | tr -d '\r\n')" && [[ -n "${token}" ]]; then
    printf '%s' "${token}" >"${OUT_FILE}"
    chmod 600 "${OUT_FILE}"
    exit 0
  fi

  sleep 5
done

echo "pangolin setup token not available (is pangolin healthy? ssh ${SSH_USER}@${SSH_HOST} sudo docker logs pangolin)" >&2
exit 1
