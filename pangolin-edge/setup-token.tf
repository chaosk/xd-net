resource "null_resource" "fetch_pangolin_setup_token" {
  count = local.install_enabled ? 1 : 0

  triggers = null_resource.pangolin_vm_install[0].triggers

  provisioner "local-exec" {
    command = "${path.module}/scripts/fetch-setup-token.sh"
    environment = {
      SSH_HOST     = local.public_ip
      SSH_USER     = var.ssh_user
      SSH_KEY_PATH = local.ssh_private_key_path_output
      REMOTE_PATH  = var.remote_install_dir
      OUT_FILE     = abspath("${path.module}/_out/pangolin-setup-token")
    }
  }

  depends_on = [null_resource.pangolin_vm_install[0]]
}

locals {
  setup_token_file = abspath("${path.module}/_out/pangolin-setup-token")
  pangolin_setup_token = (
    local.install_enabled && fileexists(local.setup_token_file)
    ? trimspace(file(local.setup_token_file))
    : null
  )
}
