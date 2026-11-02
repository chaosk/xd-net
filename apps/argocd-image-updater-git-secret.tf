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
    # Verify GitHub's SSH host key on push (Image Updater >= v1.4.0; older versions ignore it).
    # Checked against /app/config/ssh/ssh_known_hosts, mounted from argocd-ssh-known-hosts-cm.
    insecure = "false"
  }

  depends_on = [module.argocd]
}
