# ============================================
# CREDENTIALS
# ============================================

output "talosconfig" {
  value       = data.talos_client_configuration.client.talos_config
  sensitive   = true
  description = "Talos configuration for cluster management"
}

output "kubeconfig" {
  value       = talos_cluster_kubeconfig.kc.kubeconfig_raw
  sensitive   = true
  description = "Kubernetes configuration for cluster access"
}

# ============================================
# CLUSTER INFO
# ============================================

output "cluster_info" {
  value = {
    cluster_name     = var.cluster_name
    cluster_endpoint = local.cluster_endpoint
    node_count       = length(local.nodes)
    nodes = { for n in local.nodes : n.name => {
      fqdn        = n.fqdn
      vmid        = n.vmid
      gpu_enabled = n.gpu
    } }
  }
  description = "Cluster overview"
}

output "vm_ids" {
  value       = { for k, v in proxmox_vm_qemu.nodes : k => v.vmid }
  description = "VM IDs for each node"
}

output "control_planes" {
  value = {
    count = length(local.control_planes)
    nodes = { for n in local.control_planes : n.name => {
      fqdn        = n.fqdn
      vmid        = n.vmid
      gpu_enabled = n.gpu
    } }
  }
  description = "Control plane nodes information"
}

output "workers" {
  value = {
    count = length(local.workers)
    nodes = { for n in local.workers : n.name => {
      fqdn        = n.fqdn
      vmid        = n.vmid
      gpu_enabled = n.gpu
    } }
  }
  description = "Worker nodes information"
}

# ============================================
# CONFIGURATION SUMMARIES
# ============================================

output "security_config" {
  value = {
    network_policies_enabled = var.enable_network_policies
    default_deny_ingress     = var.default_deny_ingress
  }
  description = "Security configuration summary"
}

# ============================================
# NEXT STEPS
# ============================================

output "next_steps" {
  value       = <<-EOT

    🎉 Homelab cluster provisioned successfully!

    Next steps:
    1. Install CRDs: cd ../app-manifests && terraform apply
    4. Install apps: cd ../apps && terraform apply

    Cluster: ${var.cluster_name}
    Control Planes: ${length(local.control_planes)}
    Workers: ${length(local.workers)}
    Total Nodes: ${length(local.nodes)}

  EOT
  description = "Instructions for next steps"
}
