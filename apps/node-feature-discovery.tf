# Node Feature Discovery: CRDs + controller for Intel GpuDevicePlugin NodeFeatureRules (automatic GPU node labels).

resource "kubernetes_namespace_v1" "node_feature_discovery" {
  metadata {
    name = var.node_feature_discovery_namespace
    labels = {
      "pod-security.kubernetes.io/enforce" = "privileged"
      "pod-security.kubernetes.io/audit"   = "privileged"
      "pod-security.kubernetes.io/warn"    = "privileged"
    }
  }
}

resource "helm_release" "node_feature_discovery" {
  name             = "node-feature-discovery"
  chart            = "node-feature-discovery"
  repository       = "https://kubernetes-sigs.github.io/node-feature-discovery/charts"
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
