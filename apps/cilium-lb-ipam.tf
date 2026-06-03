# Envoy Gateway (or any LB Service using the pool) needs LB IPAM + L2 announcement;
# EXTERNAL-IP stays <pending>. Set cilium_l2_loadbalancer_ip_pool in config.auto.tfvars
# to a small unused range on the same L2 subnet as your nodes.
# https://docs.cilium.io/en/stable/network/l2-announcements/

locals {
  cilium_l2_pool_enabled = var.cilium_l2_loadbalancer_ip_pool != null
}

resource "kubernetes_manifest" "cilium_loadbalancer_ip_pool" {
  count = local.cilium_l2_pool_enabled ? 1 : 0

  manifest = {
    apiVersion = "cilium.io/v2"
    kind       = "CiliumLoadBalancerIPPool"
    metadata = {
      name = "gateway-lb-pool"
    }
    spec = {
      blocks = [
        {
          start = var.cilium_l2_loadbalancer_ip_pool.start
          stop  = var.cilium_l2_loadbalancer_ip_pool.stop
        }
      ]
      disabled = false
    }
  }

  depends_on = [cilium.cilium]
}

resource "kubernetes_manifest" "cilium_l2_announcement_policy" {
  count = local.cilium_l2_pool_enabled ? 1 : 0

  manifest = {
    apiVersion = "cilium.io/v2alpha1"
    kind       = "CiliumL2AnnouncementPolicy"
    metadata = {
      name = "gateway-l2-announce"
    }
    spec = merge(
      {
        externalIPs     = false
        loadBalancerIPs = true
        # Envoy Gateway proxy Service labels (see gateway.envoyproxy.io/owning-gateway-*).
        serviceSelector = {
          matchLabels = {
            "gateway.envoyproxy.io/owning-gateway-name"      = var.gateway_name
            "gateway.envoyproxy.io/owning-gateway-namespace" = var.gateway_namespace
          }
        }
      },
      local.gateway_pin_enabled ? {
        nodeSelector = {
          matchLabels = local.gateway_node_selector
        }
      } : {},
      length(var.cilium_l2_announcement_interfaces) > 0 ? { interfaces = var.cilium_l2_announcement_interfaces } : {}
    )
  }

  depends_on = [
    cilium.cilium,
    kubernetes_manifest.cilium_loadbalancer_ip_pool,
    kubernetes_labels.gateway_node,
  ]
}
