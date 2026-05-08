resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = var.namespace
  create_namespace = true
  wait             = true

  values = [
    yamlencode({
      crds = {
        install = false
      }
      configs = {
        cmp = {
          plugins = {
            sops = {
              generate = {
                command = ["sh", "-c", "sops -d $ARGOCD_APP_SOURCE_PATH/**/*.yaml"]
              }
            }
          }
        }
      }
      server = {
        service = {
          type = var.use_gateway_api ? "ClusterIP" : var.service_type
        }
      }
    })
  ]
}

locals {
  gateway_name = "argocd-gateway"
}

resource "kubernetes_manifest" "gateway" {
  count = var.use_gateway_api ? 1 : 0

  manifest = {
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "Gateway"
    metadata = {
      name      = local.gateway_name
      namespace = var.namespace
      annotations = {
        "cert-manager.io/cluster-issuer" = var.cluster_issuer_name
      }
    }
    spec = {
      gatewayClassName = var.gateway_class_name
      listeners = [
        {
          name     = "http"
          protocol = "HTTP"
          port     = 80
          hostname = var.host
          allowedRoutes = {
            namespaces = {
              from = "Same"
            }
          }
        },
        {
          name     = "https"
          protocol = "HTTPS"
          port     = 443
          hostname = var.host
          allowedRoutes = {
            namespaces = {
              from = "Same"
            }
          }
          tls = {
            mode = "Terminate"
            certificateRefs = [
              {
                name  = var.tls_secret_name
                kind  = "Secret"
                group = ""
              }
            ]
          }
        }
      ]
    }
  }

  depends_on = [helm_release.argocd]
}

resource "kubernetes_manifest" "route" {
  count = var.use_gateway_api ? 1 : 0

  manifest = {
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "HTTPRoute"
    metadata = {
      name      = "argocd"
      namespace = var.namespace
    }
    spec = {
      parentRefs = [
        {
          name = local.gateway_name
        }
      ]
      hostnames = [var.host]
      rules = [
        {
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

  depends_on = [kubernetes_manifest.gateway]
}

