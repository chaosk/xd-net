resource "kubernetes_namespace_v1" "synology_csi" {
  metadata {
    name = "synology-csi"
    labels = {
      # Exempt from Pod Security Standards - CSI drivers need privileged access
      "pod-security.kubernetes.io/enforce" = "privileged"
      "pod-security.kubernetes.io/audit"   = "privileged"
      "pod-security.kubernetes.io/warn"    = "privileged"
    }
  }
}

resource "kubernetes_secret_v1" "synology_creds" {
  metadata {
    name      = "synology-creds"
    namespace = kubernetes_namespace_v1.synology_csi.metadata[0].name
  }

  data = {
    "client-info.yml" = yamlencode({
      clients = [
        {
          host     = var.synology_host
          port     = var.synology_port
          https    = var.synology_https
          username = var.synology_username
          password = var.synology_password
        }
      ]
    })
  }
}

resource "helm_release" "synology_csi" {
  name             = "synology-csi"
  repository       = "https://zebernst.github.io/synology-csi-talos"
  chart            = "synology-csi"
  namespace        = kubernetes_namespace_v1.synology_csi.metadata[0].name
  create_namespace = false

  set = [
    {
      name  = "clientInfoSecret.name"
      value = kubernetes_secret_v1.synology_creds.metadata[0].name
    }
  ]

  depends_on = [kubernetes_secret_v1.synology_creds]
}
