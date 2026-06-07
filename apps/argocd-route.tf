resource "kubernetes_manifest" "argocd_route" {
  manifest = {
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "HTTPRoute"
    metadata = {
      name      = "argocd"
      namespace = "argocd"
      annotations = {
        "gethomepage.dev/enabled"      = "true"
        "gethomepage.dev/group"        = "Management"
        "gethomepage.dev/weight"       = "25"
        "gethomepage.dev/name"         = "Argo CD"
        "gethomepage.dev/description"  = "GitOps deployments"
        "gethomepage.dev/icon"         = "si-argo"
        "gethomepage.dev/href"         = "https://${var.argocd_host}"
        "gethomepage.dev/pod-selector" = "app.kubernetes.io/name=argocd-server"
        "gethomepage.dev/widget.type"  = "argocd"
        "gethomepage.dev/widget.url"   = "http://argocd-server.argocd.svc.cluster.local"
        "gethomepage.dev/widget.key"   = "{{HOMEPAGE_VAR_ARGOCD_API_KEY}}"
        "gethomepage.dev/widget.fields" = "[\"synced\", \"outOfSync\", \"healthy\", \"degraded\"]"
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
      hostnames = [var.argocd_host]
      rules = [
        {
          filters = [
            {
              type = "RequestHeaderModifier"
              requestHeaderModifier = {
                set = [
                  {
                    name  = "X-Forwarded-Proto"
                    value = "https"
                  },
                  {
                    name  = "X-Forwarded-Port"
                    value = "443"
                  }
                ]
              }
            }
          ]
          backendRefs = [
            {
              name = "argocd-server"
              port = 80
            }
          ]
        }
      ]
    }
  }

  depends_on = [
    module.argocd,
    kubernetes_manifest.shared_gateway,
  ]
}

