resource "kubernetes_manifest" "synology_storageclass" {
  manifest = {
    apiVersion = "storage.k8s.io/v1"
    kind       = "StorageClass"
    metadata = {
      name = "synology"
      annotations = {
        "storageclass.kubernetes.io/is-default-class" = "true"
      }
    }
    provisioner = "csi.san.synology.com"
    parameters = {
      fsType   = "ext4"
      protocol = "iscsi"
    }
    reclaimPolicy     = "Delete"
    volumeBindingMode = "Immediate"
  }

  depends_on = [helm_release.synology_csi]
}

