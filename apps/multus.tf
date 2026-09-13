# Multus meta-CNI for secondary pod interfaces (macvlan). Primary pod networking stays Cilium.
# Requires cni.exclusive=false on Cilium (see cilium.tf).
# https://docs.siderolabs.com/kubernetes-guides/cni/multus
#
# kubectl apply -k is idempotent. Hash local manifests in triggers_replace so a
# kustomize pin bump replaces this resource and re-runs the create provisioner.
# (Updating `input` in place does not re-run when=create.) Do not kubectl delete
# on that replace (it would flap the CNI). Uninstall only when count goes to 0.

locals {
  multus_manifest_hash = sha256(join("\n", [
    for f in sort(fileset("${path.module}/multus", "**/{*.yaml,*.yml}")) :
    "${f}:${filesha256("${path.module}/multus/${f}")}"
  ]))
}

resource "terraform_data" "multus" {
  count = var.multus_enabled ? 1 : 0

  triggers_replace = local.multus_manifest_hash

  input = {
    kubeconfig = abspath(var.kubeconfig_path)
    dir        = abspath("${path.module}/multus")
  }

  provisioner "local-exec" {
    when    = create
    command = "kubectl --kubeconfig=${self.input.kubeconfig} apply -k ${self.input.dir}"
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [cilium.cilium]
}

resource "terraform_data" "multus_uninstall" {
  count = var.multus_enabled ? 1 : 0

  input = {
    kubeconfig = abspath(var.kubeconfig_path)
    dir        = abspath("${path.module}/multus")
  }

  provisioner "local-exec" {
    when    = destroy
    command = "kubectl --kubeconfig=${self.input.kubeconfig} delete --ignore-not-found -k ${self.input.dir}"
  }

  depends_on = [cilium.cilium]
}
