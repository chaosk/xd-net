# Envoy Gateway replaces Cilium's bundled envoy (gatewayAPI.enabled=false in cilium.tf).
# Install Envoy Gateway CRDs first: terraform apply in ../app-manifests/
# Supports Gateway API extensions: SecurityPolicy (ext-auth forward auth, OIDC, JWT, etc.).
# https://gateway.envoyproxy.io/docs/tasks/security/ext-auth/

resource "helm_release" "envoy_gateway" {
  name             = "envoy-gateway"
  repository       = "oci://docker.io/envoyproxy"
  chart            = "gateway-helm"
  version          = var.envoy_gateway_version
  namespace        = var.envoy_gateway_namespace
  create_namespace = true
  wait             = true
  skip_crds        = true

  values = [
    yamlencode({
      deployment = {
        replicas = var.envoy_gateway_controller_replicas
        envoyGateway = {
          resources = {
            requests = {
              cpu    = var.envoy_gateway_controller_cpu_request
              memory = var.envoy_gateway_controller_memory_request
            }
            limits = {
              cpu    = var.envoy_gateway_controller_cpu_limit
              memory = var.envoy_gateway_controller_memory_limit
            }
          }
        }
      }
    }),
  ]

  depends_on = [cilium.cilium]
}

# Dataplane resources for the shared Gateway (replaces per-node cilium-envoy).
resource "kubernetes_manifest" "envoy_proxy_config" {
  manifest = {
    apiVersion = "gateway.envoyproxy.io/v1alpha1"
    kind       = "EnvoyProxy"
    metadata = {
      name      = var.envoy_proxy_config_name
      namespace = var.gateway_namespace
    }
    spec = {
      provider = {
        type = "Kubernetes"
        kubernetes = {
          envoyDeployment = {
            replicas = var.envoy_proxy_replicas
            container = {
              resources = {
                requests = {
                  cpu    = var.envoy_proxy_cpu_request
                  memory = var.envoy_proxy_memory_request
                }
                limits = {
                  cpu    = var.envoy_proxy_cpu_limit
                  memory = var.envoy_proxy_memory_limit
                }
              }
            }
          }
          envoyService = {
            type                      = "LoadBalancer"
            externalTrafficPolicy     = var.envoy_proxy_external_traffic_policy
          }
        }
      }
    }
  }

  depends_on = [
    helm_release.envoy_gateway,
    kubernetes_namespace_v1.gateway,
  ]
}
