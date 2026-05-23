#!/usr/bin/env bash
# Register Traefik CrowdSec bouncer and inject API key into dynamic_config.yml.
# Run on the VM from the compose project directory (e.g. /opt/pangolin).
set -euo pipefail

INSTALL_DIR="${1:-.}"
cd "${INSTALL_DIR}"

DYNAMIC_CONFIG="config/traefik/dynamic_config.yml"
PLACEHOLDER="__CROWDSEC_BOUNCER_KEY__"

if ! grep -q "${PLACEHOLDER}" "${DYNAMIC_CONFIG}" 2>/dev/null; then
  exit 0
fi

echo "Waiting for CrowdSec..."
for _ in $(seq 1 60); do
  if sudo docker compose exec -T crowdsec cscli version >/dev/null 2>&1; then
    break
  fi
  sleep 2
done

sudo docker compose exec -T crowdsec cscli bouncers delete traefik >/dev/null 2>&1 || true
KEY="$(sudo docker compose exec -T crowdsec cscli bouncers add traefik -o raw)"
KEY="$(echo "${KEY}" | tr -d '\r\n')"

if [[ -z "${KEY}" ]]; then
  echo "Failed to create CrowdSec bouncer key for Traefik" >&2
  exit 1
fi

sed -i "s|${PLACEHOLDER}|${KEY}|g" "${DYNAMIC_CONFIG}"
chmod 600 "${DYNAMIC_CONFIG}"

sudo docker compose restart traefik
echo "CrowdSec bouncer configured for Traefik."
