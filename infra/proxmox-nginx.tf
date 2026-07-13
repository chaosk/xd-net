# nginx on the Proxmox host: HTTPS :443 → pveproxy :8006
# https://pve.proxmox.com/wiki/Web_Interface_Via_Nginx_Proxy
# ACME: https://pve.proxmox.com/wiki/Certificate_Management (use DNS-01 — nginx uses :80)

locals {
  pm_api_authority = trimprefix(trimprefix(var.pm_api_url, "https://"), "http://")
  pm_api_host_port = split("/", local.pm_api_authority)[0]
  pm_api_host      = split(":", local.pm_api_host_port)[0]

  proxmox_ssh_host = coalesce(var.proxmox_ssh_host, local.pm_api_host)

  proxmox_nginx_install_script = file("${path.module}/proxmox-nginx/install.sh")
  proxmox_nginx_conf_template  = file("${path.module}/proxmox-nginx/proxmox.conf.tmpl")
  proxmox_nginx_systemd_dropin = file("${path.module}/proxmox-nginx/nginx.service.d-override.conf")
}

resource "null_resource" "proxmox_nginx_proxy" {
  count = var.proxmox_nginx_proxy_enabled ? 1 : 0

  triggers = {
    host       = local.proxmox_ssh_host
    user       = var.proxmox_ssh_user
    install_sh = sha256(local.proxmox_nginx_install_script)
    conf_tmpl  = sha256(local.proxmox_nginx_conf_template)
    systemd    = sha256(local.proxmox_nginx_systemd_dropin)
  }

  connection {
    type        = "ssh"
    host        = local.proxmox_ssh_host
    user        = var.proxmox_ssh_user
    port        = var.proxmox_ssh_port
    private_key = file(var.proxmox_ssh_private_key_path)
    timeout     = "2m"
  }

  provisioner "remote-exec" {
    inline = ["mkdir -p /tmp/proxmox-nginx"]
  }

  provisioner "file" {
    content     = local.proxmox_nginx_install_script
    destination = "/tmp/proxmox-nginx/install.sh"
  }

  provisioner "file" {
    content     = local.proxmox_nginx_conf_template
    destination = "/tmp/proxmox-nginx/proxmox.conf.tmpl"
  }

  provisioner "file" {
    content     = local.proxmox_nginx_systemd_dropin
    destination = "/tmp/proxmox-nginx/nginx.service.d-override.conf"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/proxmox-nginx/install.sh",
      "bash /tmp/proxmox-nginx/install.sh /tmp/proxmox-nginx",
    ]
  }
}
