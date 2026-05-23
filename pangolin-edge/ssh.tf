# Ed25519 key for the OCI instance unless ssh_public_key_path / ssh_private_key_path are set.

resource "tls_private_key" "ssh" {
  count = local.use_generated_ssh_key ? 1 : 0

  algorithm = "ED25519"
}

resource "local_sensitive_file" "ssh_private_key" {
  count = local.use_generated_ssh_key ? 1 : 0

  content         = tls_private_key.ssh[0].private_key_openssh
  filename        = "${path.module}/_out/ssh/pangolin-edge"
  file_permission = "0600"
}

resource "local_file" "ssh_public_key" {
  count = local.use_generated_ssh_key ? 1 : 0

  content         = "${trimspace(tls_private_key.ssh[0].public_key_openssh)}\n"
  filename        = "${path.module}/_out/ssh/pangolin-edge.pub"
  file_permission = "0644"
}
