resource "kubernetes_manifest" "argocd_platform_secrets" {
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = "platform-secrets"
      namespace = "argocd"
    }
    spec = {
      project = "default"
      source = {
        repoURL        = var.git_repo_url
        targetRevision = var.git_revision
        path           = var.git_path_secrets
        plugin = {
          name = "sops"
        }
      }
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = "argocd"
      }
      syncPolicy = {
        automated = {
          prune    = true
          selfHeal = true
        }
        syncOptions = ["CreateNamespace=true"]
      }
    }
  }

  depends_on = [module.argocd, kubernetes_secret_v1.argocd_repo_ssh]
}

resource "kubernetes_manifest" "argocd_apps_applicationset" {
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "ApplicationSet"
    metadata = {
      name      = "apps"
      namespace = "argocd"
    }
    spec = {
      generators = [
        {
          git = {
            repoURL  = var.git_repo_url
            revision = var.git_revision
            directories = [
              {
                path = "${var.git_path_apps}/*"
              }
            ]
          }
        }
      ]
      template = {
        metadata = {
          name = "{{path.basename}}"
        }
        spec = {
          project = "default"
          source = {
            repoURL        = var.git_repo_url
            targetRevision = var.git_revision
            path           = "{{path}}"
          }
          destination = {
            server    = "https://kubernetes.default.svc"
            namespace = "{{path.basename}}"
          }
          syncPolicy = {
            automated = {
              prune    = true
              selfHeal = true
            }
            syncOptions = ["CreateNamespace=true"]
          }
        }
      }
    }
  }

  depends_on = [module.argocd, kubernetes_secret_v1.argocd_repo_ssh]
}

