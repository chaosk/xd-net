resource "kubernetes_manifest" "acme_cluster_issuer" {
  computed_fields = ["spec.acme.solvers"]

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
                config = merge(
                  {
                    # cert-manager-webhook-vercel expects apiKeySecretRef.
                    apiKeySecretRef = {
                      name = kubernetes_secret_v1.vercel_api_token.metadata[0].name
                      key  = "token"
                    }
                  },
                  var.vercel_team_id != null ? { teamId = var.vercel_team_id } : {},
                  var.vercel_team_slug != null ? { teamSlug = var.vercel_team_slug } : {},
                )
              }
            }
          }
        ]
      }
    }
  }

  depends_on = [helm_release.certmanager, helm_release.cert_manager_webhook_vercel]
}
