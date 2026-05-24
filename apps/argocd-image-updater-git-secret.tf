# Argo CD Image Updater git write-back (SSH). Separate deploy key from repo-gitops (read-only).
# See: https://argocd-image-updater.readthedocs.io/en/stable/basics/update-methods/#method-git-credentials

resource "kubernetes_secret_v1" "argocd_image_updater_git" {
  count = trimspace(var.git_image_updater_ssh_private_key) != "" ? 1 : 0

  metadata {
    name      = var.git_image_updater_secret
    namespace = "argocd"
  }

  data = {
    sshPrivateKey = var.git_image_updater_ssh_private_key
  }

  depends_on = [module.argocd]
}
