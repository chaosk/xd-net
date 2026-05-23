#!/usr/bin/env bash
# Sync Terraform-rendered bundle (_out/deploy) to the OCI VM and start compose.
# Usage: ./scripts/push-deploy.sh [user@host] [/opt/pangolin]
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEPLOY="${ROOT}/_out/deploy"
REMOTE="${1:-}"
INSTALL_DIR="${2:-/opt/pangolin}"
SSH_IDENTITY="${SSH_IDENTITY:-}"

if [[ -z "${REMOTE}" ]]; then
  echo "Usage: SSH_IDENTITY=path/to/key $0 user@host [/opt/pangolin]" >&2
  echo "Run 'terraform apply' in pangolin-edge first to generate _out/deploy." >&2
  exit 1
fi

if [[ ! -f "${DEPLOY}/docker-compose.yml" ]]; then
  echo "Missing ${DEPLOY}/docker-compose.yml — run: cd ${ROOT} && terraform apply" >&2
  exit 1
fi

SSH_OPTS=()
[[ -n "${SSH_IDENTITY}" ]] && SSH_OPTS+=(-i "${SSH_IDENTITY}")

ssh "${SSH_OPTS[@]}" "${REMOTE}" "sudo mkdir -p ${INSTALL_DIR} && sudo chown -R \$(whoami):\$(whoami) ${INSTALL_DIR}"
rsync -avz --delete -e "ssh ${SSH_OPTS[*]}" "${DEPLOY}/" "${REMOTE}:${INSTALL_DIR}/"

ssh "${SSH_OPTS[@]}" "${REMOTE}" bash -s -- "${INSTALL_DIR}" <<'REMOTE'
set -euo pipefail
INSTALL_DIR="$1"
cd "${INSTALL_DIR}"
mkdir -p config/traefik/logs config/db config/letsencrypt config/crowdsec/db
touch config/letsencrypt/acme.json config/traefik/logs/access.log
chmod 600 config/letsencrypt/acme.json
if ! command -v docker >/dev/null 2>&1; then
  curl -fsSL https://get.docker.com | sudo sh
fi
if [[ -x ./vm-install.sh ]]; then
  bash ./vm-install.sh
else
  sudo docker compose pull
  sudo docker compose up -d
  if [[ -x ./configure-crowdsec-bouncer.sh ]]; then
    ./configure-crowdsec-bouncer.sh "${INSTALL_DIR}"
  fi
fi
echo "Done. Initial setup: see README.txt in ${INSTALL_DIR}"
REMOTE
