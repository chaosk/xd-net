# Preserve the original client IP for upstream apps (Authentik audit logs, GeoIP, IP policies).
# Envoy Gateway appends X-Forwarded-For when proxying; Authentik trusts 10.0.0.0/8 by default.
# Set gateway_node_name (label target) + envoy_proxy_external_traffic_policy = "Local" so L2 and Envoy share that worker.
resource "kubernetes_manifest" "gateway_client_traffic_policy" {
  manifest = {
    apiVersion = "gateway.envoyproxy.io/v1alpha1"
    kind       = "ClientTrafficPolicy"
    metadata = {
      name      = "client-ip-detection"
      namespace = kubernetes_namespace_v1.gateway.metadata[0].name
    }
    spec = {
      targetRefs = [
        {
          group = "gateway.networking.k8s.io"
          kind  = "Gateway"
          name  = var.gateway_name
        },
      ]
      clientIPDetection = {
        xForwardedFor = {
          numTrustedHops = var.gateway_xff_num_trusted_hops
        }
      }
    }
  }

  depends_on = [kubernetes_manifest.shared_gateway]
}
