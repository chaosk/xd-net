# Node Feature Discovery: CRDs + controller for Intel GpuDevicePlugin NodeFeatureRules (automatic GPU node labels).

resource "kubernetes_namespace_v1" "node_feature_discovery" {
  metadata {
    name = var.node_feature_discovery_namespace
    labels = {
      # Must stay privileged (PSS baseline forbids hostPath). nfd-worker mounts
      # host /boot, /sys, /lib, /usr/lib, /etc/os-release, /proc/swaps, and
      # features.d via hostPath (chart v0.19.0). See XD-45.
      "pod-security.kubernetes.io/enforce" = "privileged"
      "pod-security.kubernetes.io/audit"   = "privileged"
      "pod-security.kubernetes.io/warn"    = "privileged"
    }
  }
}

resource "helm_release" "node_feature_discovery" {
  name             = "node-feature-discovery"
  chart            = "node-feature-discovery"
  repository       = "oci://registry.k8s.io/nfd/charts"
  version          = var.node_feature_discovery_chart_version
  namespace        = kubernetes_namespace_v1.node_feature_discovery.metadata[0].name
  create_namespace = false

  values = [
    yamlencode(merge(
      {
        master = {
          extraLabelNs = [
            "intel.feature.node.kubernetes.io",
            "gpu.intel.com",
          ]
        }
      },
      var.node_feature_discovery_extra_values
    ))
  ]

  depends_on = [kubernetes_namespace_v1.node_feature_discovery]
}
