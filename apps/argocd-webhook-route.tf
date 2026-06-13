# Pangolin only (pangolin-operator/site-ref → NewtSite). GitHub POST /api/webhook refreshes
# Applications without waiting for the 3-minute poll. Only /api/webhook — not the Argo CD UI
# (homelab: argocd-route.tf on argocd.net.ecksd.ee).
# https://argo-cd.readthedocs.io/en/stable/operator-manual/webhook/
resource "kubernetes_manifest" "argocd_webhook_route" {
  count = local.pangolin_operator_helm ? 1 : 0

  manifest = {
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "HTTPRoute"
    metadata = {
      name      = "argocd-webhook-pangolin"
      namespace = "argocd"
      annotations = {
        "pangolin-operator/site-ref"           = var.pangolin_newtsite_name
        # HTTPRoute path rules only apply on the in-cluster Gateway; Pangolin edge routing
        # needs these or the whole hostname is published (operator README).
        "pangolin-operator/target-path"       = "/api/webhook"
        "pangolin-operator/target-path-match" = "prefix"
      }
    }
    spec = {
      parentRefs = [
        {
          name        = var.gateway_name
          namespace   = var.gateway_namespace
          sectionName = "https"
        },
      ]
      hostnames = [var.argocd_webhook_host]
      rules = [
        {
          matches = [
            {
              path = {
                type  = "PathPrefix"
                value = "/api/webhook"
              }
            },
          ]
          backendRefs = [
            {
              name = "argocd-server"
              port = 80
            },
          ]
        },
      ]
    }
  }

  depends_on = [
    module.argocd,
    kubernetes_manifest.shared_gateway,
    kubernetes_manifest.pangolin_newtsite,
  ]
}
