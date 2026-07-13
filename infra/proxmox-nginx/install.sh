#!/usr/bin/env bash
# Installed on the Proxmox host by Terraform (infra/proxmox-nginx.tf).
# https://pve.proxmox.com/wiki/Web_Interface_Via_Nginx_Proxy
set -euo pipefail

INSTALL_DIR="${1:-/tmp/proxmox-nginx}"

if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
  echo "Run as root on the Proxmox node." >&2
  exit 1
fi

if ! command -v pveversion >/dev/null 2>&1; then
  echo "pveversion not found — is this a Proxmox VE host?" >&2
  exit 1
fi

# ACME / custom certs for pveproxy → pveproxy-ssl.* (see Certificate Management wiki).
# Otherwise fall back to the node cluster CA cert on :443 (browser warnings).
if [[ -f /etc/pve/local/pveproxy-ssl.pem && -f /etc/pve/local/pveproxy-ssl.key ]]; then
  SSL_CERT="/etc/pve/local/pveproxy-ssl.pem"
  SSL_KEY="/etc/pve/local/pveproxy-ssl.key"
else
  SSL_CERT="/etc/pve/local/pve-ssl.pem"
  SSL_KEY="/etc/pve/local/pve-ssl.key"
fi

export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y nginx gettext-base

if [[ -e /etc/nginx/sites-enabled/default ]]; then
  rm /etc/nginx/sites-enabled/default
fi
if [[ -e /etc/nginx/conf.d/default ]]; then
  rm /etc/nginx/conf.d/default
fi

export SSL_CERT SSL_KEY
envsubst '${SSL_CERT} ${SSL_KEY}' \
  < "${INSTALL_DIR}/proxmox.conf.tmpl" \
  > /etc/nginx/conf.d/proxmox.conf

mkdir -p /etc/systemd/system/nginx.service.d
install -m 0644 "${INSTALL_DIR}/nginx.service.d-override.conf" \
  /etc/systemd/system/nginx.service.d/pve-cluster.conf

nginx -t
systemctl daemon-reload
systemctl enable nginx
systemctl restart nginx

echo "nginx proxy OK — https://$(hostname -f 2>/dev/null || hostname)/ (cert: ${SSL_CERT})"
