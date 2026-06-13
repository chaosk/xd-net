# Multus meta-CNI for secondary pod interfaces (macvlan). Primary pod networking stays Cilium.
# Requires cni.exclusive=false on Cilium (see cilium.tf).
# https://docs.siderolabs.com/kubernetes-guides/cni/multus

resource "terraform_data" "multus" {
  count = var.multus_enabled ? 1 : 0

  input = {
    kubeconfig = abspath(var.kubeconfig_path)
    dir        = abspath("${path.module}/multus")
  }

  provisioner "local-exec" {
    when    = create
    command = "kubectl --kubeconfig=${self.input.kubeconfig} apply -k ${self.input.dir}"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "kubectl --kubeconfig=${self.input.kubeconfig} delete --ignore-not-found -k ${self.input.dir}"
  }

  depends_on = [cilium.cilium]
}
