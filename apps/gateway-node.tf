# Pin north/south Gateway (Envoy + Cilium L2) to one worker via a node label.
locals {
  gateway_pin_enabled = trimspace(var.gateway_node_name) != ""
  gateway_node_selector = {
    (var.gateway_node_label.key) = var.gateway_node_label.value
  }
}

resource "kubernetes_labels" "gateway_node" {
  count = local.gateway_pin_enabled ? 1 : 0

  api_version = "v1"
  kind        = "Node"
  metadata {
    name = var.gateway_node_name
  }
  labels = local.gateway_node_selector
}
