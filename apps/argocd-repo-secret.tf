# Argo CD discovers Secrets in argocd labeled argocd.argoproj.io/secret-type=repository.
# See: https://argo-cd.readthedocs.io/en/stable/operator-manual/declarative-setup/#repositories

resource "kubernetes_secret_v1" "argocd_repo_ssh" {
  count = trimspace(var.git_repo_ssh_private_key) != "" ? 1 : 0

  metadata {
    name      = var.git_repo_credentials_secret_name
    namespace = "argocd"
    labels = {
      "argocd.argoproj.io/secret-type" = "repository"
    }
  }

  data = {
    url           = var.git_repo_url
    sshPrivateKey = var.git_repo_ssh_private_key
  }

  depends_on = [module.argocd]
}
