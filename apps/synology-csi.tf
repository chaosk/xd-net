resource "kubernetes_namespace_v1" "synology_csi" {
  metadata {
    name = "synology-csi"
    labels = {
      # Must stay privileged (PSS baseline forbids hostPath + privileged + hostNetwork).
      # synology-csi node DaemonSet: privileged containers, hostNetwork, hostPath
      # mounts (/var/lib/kubelet, /dev, host root for chroot). See XD-45.
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
  version          = "0.9.4"
  namespace        = kubernetes_namespace_v1.synology_csi.metadata[0].name
  create_namespace = false

  # Helm index may lag behind GitHub main; empty tag in chart = Chart.AppVersion.
  # Override driver: https://github.com/SynologyOpenSource/synology-csi/releases
  set = [
    {
      name  = "clientInfoSecret.name"
      value = kubernetes_secret_v1.synology_creds.metadata[0].name
    },
    {
      name  = "images.plugin.tag"
      value = "v1.2.0"
    },
  ]

  depends_on = [kubernetes_secret_v1.synology_creds]
}
