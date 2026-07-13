check "proxmox_nginx_ssh_key" {
  assert {
    condition = (
      !var.proxmox_nginx_proxy_enabled
      || (var.proxmox_ssh_private_key_path != null && trimspace(var.proxmox_ssh_private_key_path) != "")
    )
    error_message = "proxmox_ssh_private_key_path is required when proxmox_nginx_proxy_enabled is true."
  }
}
