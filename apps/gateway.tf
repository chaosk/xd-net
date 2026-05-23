resource "kubernetes_namespace_v1" "gateway" {
  metadata {
    name = var.gateway_namespace
  }
}

resource "kubernetes_manifest" "gateway_tls_certificate" {
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "Certificate"
    metadata = {
      name      = var.gateway_tls_secret_name
      namespace = kubernetes_namespace_v1.gateway.metadata[0].name
    }
    spec = {
      secretName = var.gateway_tls_secret_name
      dnsNames   = var.gateway_tls_dns_names
      issuerRef = {
        kind = "ClusterIssuer"
        name = var.acme_cluster_issuer_name
      }
    }
  }

  depends_on = [
    helm_release.certmanager,
    kubernetes_manifest.acme_cluster_issuer,
  ]
}

resource "kubernetes_manifest" "shared_gateway" {
  manifest = {
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "Gateway"
    metadata = {
      name      = var.gateway_name
      namespace = kubernetes_namespace_v1.gateway.metadata[0].name
    }
    spec = {
      gatewayClassName = var.gateway_class_name
      infrastructure = {
        parametersRef = {
          group = "gateway.envoyproxy.io"
          kind  = "EnvoyProxy"
          name  = var.envoy_proxy_config_name
        }
      }
      listeners = [
        {
          name     = "http"
          protocol = "HTTP"
          port     = 80
          allowedRoutes = {
            namespaces = {
              from = "All"
            }
          }
        },
        {
          name     = "https"
          protocol = "HTTPS"
          port     = 443
          allowedRoutes = {
            namespaces = {
              from = "All"
            }
          }
          tls = {
            mode = "Terminate"
            certificateRefs = [
              {
                name  = var.gateway_tls_secret_name
                kind  = "Secret"
                group = ""
              }
            ]
          }
        },
      ]
    }
  }

  depends_on = [
    helm_release.envoy_gateway,
    kubernetes_manifest.envoy_proxy_config,
    kubernetes_manifest.gateway_tls_certificate,
  ]
}

