# Proxmox web UI on HTTPS :443 (nginx)

Nginx reverse proxy on **pve.net.ecksd.ee** so the Proxmox UI is on **443** instead of **8006**. Installed from `infra/proxmox-nginx.tf` when `proxmox_nginx_proxy_enabled` is set.

Based on [Web Interface Via Nginx Proxy](https://pve.proxmox.com/wiki/Web_Interface_Via_Nginx_Proxy).

## ACME (Let's Encrypt)

Uses [Proxmox Certificate Management](https://pve.proxmox.com/wiki/Certificate_Management). ACME writes the trusted cert to **`/etc/pve/local/pveproxy-ssl.pem`** (+ `.key`). pveproxy on :8006 and nginx on :443 both use it (install script auto-detects).

Use **DNS-01**, not HTTP-01: nginx already owns **port 80** (HTTPS redirect), so the built-in ACME HTTP challenge cannot bind :80. DNS plugin under **Datacenter → ACME** is Vercel (same provider as cluster cert-manager).

Order of operations:

1. `terraform apply` in `infra/` (UI on :443 with cluster CA cert until ACME exists).
2. ACME account + DNS plugin in the Proxmox UI; order cert for `pve.net.ecksd.ee`.
3. Re-run `terraform apply` (or SSH and re-run install) so nginx picks up `pveproxy-ssl.pem`.

Browser UI: **https://pve.net.ecksd.ee/**. Terraform still talks to pveproxy on `:8006` via `pm_api_url` in `infra/config.auto.tfvars`.

`reload-on-cert-renewal.sh` is installed via cron (hourly) so nginx reloads when `pve-daily-update` renews the ACME cert.

## Terraform (`infra/config.auto.tfvars`)

```hcl
proxmox_nginx_proxy_enabled  = true
proxmox_ssh_private_key_path = "~/.ssh/id_ed25519"
```

SSH as root to the Proxmox node (`proxmox_ssh_host` defaults to the hostname from `pm_api_url`).

## Manual reinstall

```bash
scp -r infra/proxmox-nginx root@pve.net.ecksd.ee:/tmp/
ssh root@pve.net.ecksd.ee 'bash /tmp/proxmox-nginx/install.sh /tmp/proxmox-nginx'
```
