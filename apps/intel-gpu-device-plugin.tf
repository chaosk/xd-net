resource "kubernetes_namespace_v1" "intel_device_plugins" {
  metadata {
    name = var.intel_gpu_device_plugins_namespace
    labels = {
      "pod-security.kubernetes.io/enforce" = "privileged"
      "pod-security.kubernetes.io/audit"   = "privileged"
      "pod-security.kubernetes.io/warn"    = "privileged"
    }
  }
}

resource "helm_release" "intel_device_plugins_operator" {
  name             = "intel-device-plugins-operator"
  chart            = "intel-device-plugins-operator"
  repository       = "https://intel.github.io/helm-charts"
  version          = var.intel_gpu_operator_chart_version
  namespace        = kubernetes_namespace_v1.intel_device_plugins.metadata[0].name
  create_namespace = false

  values = [
    yamlencode({
      manager = {
        devices = {
          gpu = true
        }
      }
    })
  ]

  depends_on = [kubernetes_namespace_v1.intel_device_plugins]
}

resource "helm_release" "intel_device_plugins_gpu" {
  name             = "intel-device-plugins-gpu"
  chart            = "intel-device-plugins-gpu"
  repository       = "https://intel.github.io/helm-charts"
  version          = var.intel_gpu_plugin_chart_version
  namespace        = kubernetes_namespace_v1.intel_device_plugins.metadata[0].name
  create_namespace = false

  values = [
    yamlencode(merge(
      {
        name            = var.intel_gpu_plugin_resource_name
        nodeFeatureRule = true
        sharedDevNum    = var.intel_gpu_plugin_shared_dev_num
      },
      var.intel_gpu_plugin_extra_values
    ))
  ]

  depends_on = [
    helm_release.intel_device_plugins_operator,
    helm_release.node_feature_discovery,
  ]
}
