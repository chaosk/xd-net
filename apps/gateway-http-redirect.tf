# Redirect all HTTP (listener "http") to HTTPS. App HTTPRoutes should use sectionName: "https".
resource "kubernetes_manifest" "gateway_http_to_https_redirect" {
  count = var.gateway_http_to_https_redirect ? 1 : 0

  manifest = {
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "HTTPRoute"
    metadata = {
      name      = "http-to-https-redirect"
      namespace = kubernetes_namespace_v1.gateway.metadata[0].name
    }
    spec = {
      parentRefs = [
        {
          name        = var.gateway_name
          namespace   = var.gateway_namespace
          sectionName = "http"
        },
      ]
      rules = [
        {
          matches = [
            {
              path = {
                type  = "PathPrefix"
                value = "/"
              }
            },
          ]
          filters = [
            {
              type = "RequestRedirect"
              requestRedirect = {
                scheme     = "https"
                statusCode = var.gateway_http_redirect_status_code
              }
            },
          ]
        },
      ]
    }
  }

  depends_on = [kubernetes_manifest.shared_gateway]
}
