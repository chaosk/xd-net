# Proxmox web UI on HTTPS :443 (nginx)

Terraform can install an nginx reverse proxy on the **Proxmox host** (`infra/proxmox-nginx.tf`) so the UI is on **443** instead of **8006**.

Based on [Web Interface Via Nginx Proxy](https://pve.proxmox.com/wiki/Web_Interface_Via_Nginx_Proxy).

## ACME (Let's Encrypt)

Works with [Proxmox Certificate Management](https://pve.proxmox.com/wiki/Certificate_Management) ACME:

1. Order the cert in Proxmox (**Node → Certificates**, or `pvenode acme cert order`).
2. ACME stores the trusted cert in **`/etc/pve/local/pveproxy-ssl.pem`** (+ `.key`). pveproxy on :8006 and nginx on :443 both use it (install script auto-detects).

**Use DNS-01**, not HTTP-01: nginx already listens on **port 80** (redirect to HTTPS), so the built-in ACME HTTP challenge cannot bind :80. Configure a DNS API plugin under **Datacenter → ACME** (e.g. Vercel — same provider as `apps/` cert-manager).

Recommended order:

1. `terraform apply` with `proxmox_nginx_proxy_enabled = true` (UI on :443 with cluster CA cert).
2. Configure ACME account + DNS plugin in Proxmox UI; order cert for `pve.net.ecksd.ee`.
3. Re-run `terraform apply` (or SSH and re-run install) so nginx picks up `pveproxy-ssl.pem`.

After ACME, update Terraform:

```hcl
pm_api_url = "https://pve.net.ecksd.ee/api2/json"
```

Optional: install `reload-on-cert-renewal.sh` via cron (hourly) so nginx reloads when `pve-daily-update` renews the ACME cert.

## Terraform variables (`infra/config.auto.tfvars`)

```hcl
proxmox_nginx_proxy_enabled   = true
proxmox_ssh_private_key_path  = "~/.ssh/id_ed25519"
# proxmox_ssh_host = "pve.net.ecksd.ee"  # default: hostname from pm_api_url
# proxmox_ssh_user = "root"
```

Requires SSH as root (or sudo) to the Proxmox node.

## Manual install (without Terraform)

```bash
scp -r infra/proxmox-nginx root@pve.net.ecksd.ee:/tmp/
ssh root@pve.net.ecksd.ee 'bash /tmp/proxmox-nginx/install.sh /tmp/proxmox-nginx'
```
