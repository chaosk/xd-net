#!/usr/bin/env bash
# Reload nginx after Proxmox ACME renewal updates pveproxy-ssl.pem.
# Install once on the host (optional): see README.md.
set -euo pipefail

STAMP="/var/lib/proxmox-nginx-pveproxy-cert.stamp"
CERT="/etc/pve/local/pveproxy-ssl.pem"

[[ -f "${CERT}" ]] || exit 0

current="$(stat -c %Y "${CERT}" 2>/dev/null || stat -f %m "${CERT}")"
previous=""
[[ -f "${STAMP}" ]] && previous="$(cat "${STAMP}")"

if [[ "${current}" != "${previous}" ]]; then
  echo "${current}" > "${STAMP}"
  nginx -t && systemctl reload nginx
fi
