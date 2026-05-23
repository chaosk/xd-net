locals {
  install_enabled = var.install_pangolin_via_ssh && local.deploy_enabled
  ufw_ssh_allow   = var.allow_ssh_cidr == "0.0.0.0/0" ? "sudo ufw allow 22/tcp" : "sudo ufw allow from ${var.allow_ssh_cidr} to any port 22 proto tcp"
  vm_install_script = templatefile("${path.module}/scripts/vm-install.sh.tmpl", {
    install_dir      = var.remote_install_dir
    ssh_user         = var.ssh_user
    enable_crowdsec  = var.enable_crowdsec
    ufw_ssh_allow    = local.ufw_ssh_allow
    logrotate_config = var.enable_crowdsec ? templatefile("${path.module}/templates/logrotate-pangolin-traefik.tmpl", { install_dir = var.remote_install_dir }) : ""
  })
}

resource "null_resource" "pangolin_vm_install" {
  count = local.install_enabled ? 1 : 0

  triggers = {
    bundle = sha256(join("", [
      local_file.deploy_compose[0].content,
      local_file.deploy_config[0].content,
      local_file.deploy_traefik_static[0].content,
      local_file.deploy_traefik_dynamic[0].content,
      var.enable_crowdsec ? file("${path.module}/scripts/configure-crowdsec-bouncer.sh") : "",
      local.vm_install_script,
    ]))
    remote_dir = var.remote_install_dir
    public_ip  = local.public_ip
  }

  connection {
    type        = "ssh"
    host        = local.public_ip
    user        = var.ssh_user
    private_key = local.ssh_private_key_openssh
    timeout     = "5m"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mkdir -p ${var.remote_install_dir}",
      "sudo chown -R ${var.ssh_user}:${var.ssh_user} ${var.remote_install_dir}",
    ]
  }

  provisioner "file" {
    source      = "${path.module}/_out/deploy/"
    destination = var.remote_install_dir
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x ${var.remote_install_dir}/vm-install.sh",
      "bash ${var.remote_install_dir}/vm-install.sh",
    ]
  }

  # install_enabled implies install_pangolin_via_ssh and generate_deploy_bundle, so [0] targets exist.
  depends_on = [
    oci_core_public_ip.pangolin,
    time_sleep.wait_for_ssh[0],
    local_file.deploy_compose[0],
    local_file.deploy_config[0],
    local_file.deploy_traefik_static[0],
    local_file.deploy_traefik_dynamic[0],
    local_file.deploy_vm_install[0],
  ]
}
