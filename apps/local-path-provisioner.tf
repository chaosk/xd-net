locals {
  local_path_node_path_map = concat(
    [
      {
        node  = "DEFAULT_PATH_FOR_NON_LISTED_NODES"
        paths = [var.local_path_default_path]
      }
    ],
    [for name, paths in var.local_path_per_node_paths : { node = name, paths = paths }]
  )
}

resource "kubernetes_namespace_v1" "local_path_storage" {
  metadata {
    name = "local-path-storage"
    labels = {
      # Must stay privileged (PSS baseline forbids hostPath). The provisioner
      # Deployment itself is fine, but PVC helper pods inject a hostPath volume
      # for the node data dir (/var/mnt/local-path-data). See XD-45.
      "pod-security.kubernetes.io/enforce" = "privileged"
      "pod-security.kubernetes.io/audit"   = "privileged"
      "pod-security.kubernetes.io/warn"    = "privileged"
    }
  }
}

resource "helm_release" "local_path_provisioner" {
  name             = "local-path-provisioner"
  chart            = "local-path-provisioner"
  repository       = "oci://ghcr.io/rancher/local-path-provisioner/charts"
  version          = var.local_path_chart_version
  namespace        = kubernetes_namespace_v1.local_path_storage.metadata[0].name
  create_namespace = false

  values = [
    yamlencode({
      storageClass = {
        create            = true
        defaultClass      = false
        name              = var.local_path_storage_class_name
        reclaimPolicy     = "Delete"
        volumeBindingMode = "WaitForFirstConsumer"
      }
      nodePathMap = local.local_path_node_path_map
    })
  ]

  depends_on = [kubernetes_namespace_v1.local_path_storage]
}
