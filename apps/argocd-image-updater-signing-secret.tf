# SSH commit signing for Image Updater git write-back (separate from deploy key).
# Public key goes on the bot account: GitHub → Settings → SSH and GPG keys → Signing keys.

resource "kubernetes_secret_v1" "argocd_image_updater_signing" {
  count = trimspace(var.git_image_updater_signing_ssh_private_key) != "" ? 1 : 0

  metadata {
    name      = var.git_image_updater_signing_secret
    namespace = "argocd"
  }

  data = {
    sshSigningKey = var.git_image_updater_signing_ssh_private_key
  }

  depends_on = [module.argocd]
}
