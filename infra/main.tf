# ============================================
# SHARED DATA SOURCES
# ============================================

data "talos_client_configuration" "client" {
  cluster_name         = var.cluster_name
  client_configuration = talos_machine_secrets.this.client_configuration
  endpoints            = [for node in local.control_planes : node.fqdn]
}
