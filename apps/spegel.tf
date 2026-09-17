# Spegel: peer-to-peer OCI registry mirror (cuts Hub 429s when a node already has the image).
# Requires Talos CRICustomizationConfig discard_unpacked_layers=false (infra/patches/spegel-cri.yaml)
# and a node reboot so containerd reloads. Helm path must be Talos hosts dir, not Docker's certs.d.
# https://docs.siderolabs.com/kubernetes-guides/advanced-guides/spegel

resource "kubernetes_namespace_v1" "spegel" {
  count = var.spegel_enabled ? 1 : 0

  metadata {
    name = var.spegel_namespace
    labels = {
      "app.kubernetes.io/managed-by"         = "terraform"
      "pod-security.kubernetes.io/enforce"   = "privileged"
      "pod-security.kubernetes.io/audit"     = "privileged"
      "pod-security.kubernetes.io/warn"      = "privileged"
    }
  }
}

resource "helm_release" "spegel" {
  count = var.spegel_enabled ? 1 : 0

  name             = "spegel"
  chart            = "spegel"
  repository       = var.spegel_chart_repository
  version          = var.spegel_chart_version
  namespace        = kubernetes_namespace_v1.spegel[0].metadata[0].name
  create_namespace = false
  wait             = true
  timeout          = 300

  values = [
    yamlencode({
      spegel = {
        containerdRegistryConfigPath = "/etc/cri/conf.d/hosts"
      }
    }),
    yamlencode(var.spegel_extra_values),
  ]

  depends_on = [kubernetes_namespace_v1.spegel]
}
