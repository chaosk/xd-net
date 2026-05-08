resource "kubernetes_manifest" "acme_cluster_issuer" {
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata = {
      name = var.acme_cluster_issuer_name
    }
    spec = {
      acme = {
        email  = var.acme_email
        server = var.acme_server
        privateKeySecretRef = {
          name = "${var.acme_cluster_issuer_name}-account-key"
        }
        solvers = [
          {
            dns01 = {
              webhook = {
                groupName  = "acme.rhythmbhiwani.in"
                solverName = "vercel"
                config = {
                  apiTokenSecretRef = {
                    name = kubernetes_secret_v1.vercel_api_token.metadata[0].name
                    key  = "token"
                  }
                }
              }
            }
          }
        ]
      }
    }
  }

  depends_on = [helm_release.certmanager, helm_release.cert_manager_webhook_vercel]
}

