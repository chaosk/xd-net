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
      "csi.storage.k8s.io/fstype" = "ext4"
      protocol                    = "iscsi"
      location                    = "/volume3"
    }
    reclaimPolicy        = "Delete"
    volumeBindingMode    = "Immediate"
    allowVolumeExpansion = true
  }

  depends_on = [helm_release.synology_csi]
}
