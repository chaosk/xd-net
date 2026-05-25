# Argo CD Image Updater GHCR API (tag listing). Bot account PAT with read:packages.
# See: https://argocd-image-updater.readthedocs.io/en/stable/configuration/registries/

resource "kubernetes_secret_v1" "argocd_image_updater_ghcr" {
  count = trimspace(var.ghcr_image_updater_token) != "" ? 1 : 0

  metadata {
    name      = var.ghcr_image_updater_secret
    namespace = "argocd"
  }

  data = {
    creds = "${var.ghcr_image_updater_username}:${var.ghcr_image_updater_token}"
  }

  depends_on = [module.argocd]
}
