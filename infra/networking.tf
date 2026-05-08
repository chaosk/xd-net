# ============================================
# DNS CONFIGURATION
# ============================================

resource "local_file" "coredns_config" {
  filename = "${var.out_dir}/coredns-custom.yaml"
  content = templatefile("${path.module}/templates/coredns-config.yaml", {
    cluster_name = var.cluster_name
    dns_servers  = var.dns_servers
    nodes = [for n in local.nodes : {
      name = n.name
      ip   = n.fqdn
    }]
  })
}

# ============================================
# NETWORK POLICIES
# ============================================

resource "local_file" "network_policies" {
  count = var.enable_network_policies ? 1 : 0

  filename = "${var.out_dir}/network-policies.yaml"
  content = templatefile("${path.module}/templates/network-policies.yaml", {
    default_deny_ingress       = var.default_deny_ingress
    default_deny_egress        = var.default_deny_egress
    allowed_ingress_namespaces = var.allowed_ingress_namespaces
    monitoring_namespace       = var.monitoring_namespace
  })
}
