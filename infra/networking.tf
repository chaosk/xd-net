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
