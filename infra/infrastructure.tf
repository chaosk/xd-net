# ============================================
# PROXMOX VMS & TALOS CONFIGURATION
# ============================================

resource "proxmox_storage_iso" "talos_iso" {
  filename = var.talos_iso_name
  pve_node = var.pm_node
  storage  = "local"
  url      = var.talos_iso_url
}

resource "proxmox_vm_qemu" "nodes" {
  for_each = { for n in local.nodes : n.name => n }

  name               = each.value.name
  target_node        = var.pm_node
  vmid               = each.value.vmid
  start_at_node_boot = true
  os_type            = "l26"

  # Organization
  tags        = "talos"
  description = "Talos K8s ${each.value.gpu ? "GPU " : ""}node - ${var.cluster_name}"

  # Hardware
  bios      = "ovmf"
  scsihw    = "virtio-scsi-pci"
  agent     = var.enable_qemu_guest_agent ? 1 : 0
  skip_ipv6 = true

  cpu {
    cores   = var.vm_cores
    sockets = 1
    limit   = var.vm_cpu_limit
  }

  memory  = var.vm_memory_mb
  balloon = var.vm_memory_ballooning ? var.vm_memory_mb / 2 : 0

  # Boot ISO
  disk {
    slot    = "ide0"
    type    = "cdrom"
    storage = "local"
    iso     = "local:iso/${var.talos_iso_name}"
  }

  disk {
    slot    = "scsi0"
    type    = "disk"
    storage = var.vm_storage
    size    = "${var.vm_disk_gb}G"
    cache   = var.vm_disk_cache
  }

  # Network
  network {
    id      = 0
    model   = var.network_model
    bridge  = var.vm_bridge
    macaddr = each.value.macaddr
    tag     = var.vm_vlan_id
  }

  # GPU passthrough for specified nodes
  dynamic "pci" {
    for_each = each.value.gpu ? [1] : []
    content {
      id          = 0
      raw_id      = "0000:03:00.0" # Update with your GPU BDF
      pcie        = true
      primary_gpu = true
      rombar      = true
    }
  }

  dynamic "pci" {
    for_each = each.value.gpu ? [1] : []
    content {
      id     = 1
      raw_id = "0000:03:00.1" # GPU audio device
      pcie   = true
      rombar = true
    }
  }

  depends_on = [proxmox_storage_iso.talos_iso]
}

# ============================================
# TALOS CONFIGURATION
# ============================================

resource "talos_machine_secrets" "this" {}

# Control plane configuration files
resource "local_file" "cp_cfg" {
  for_each = { for n in local.control_planes : n.name => n }

  filename = "${var.out_dir}/${each.value.name}-controlplane.yaml"
  content = templatefile("${path.module}/templates/node.patch.yaml.tmpl", {
    talos_version = var.talos_version
    install_disk  = "/dev/sda"
    enable_i915   = each.value.gpu
  })
}

resource "local_file" "cp_hostname_cfg" {
  for_each = { for n in local.control_planes : n.name => n }

  filename = "${var.out_dir}/${each.value.name}-hostname.yaml"
  content = templatefile("${path.module}/templates/hostname.patch.yaml.tmpl", {
    fqdn = each.value.fqdn
  })
}

# Worker configuration files
resource "local_file" "worker_cfg" {
  for_each = { for n in local.workers : n.name => n }

  filename = "${var.out_dir}/${each.value.name}-worker.yaml"
  content = templatefile("${path.module}/templates/node.patch.yaml.tmpl", {
    talos_version = var.talos_version
    install_disk  = "/dev/sda"
    enable_i915   = each.value.gpu
  })
}

resource "local_file" "worker_hostname_cfg" {
  for_each = { for n in local.workers : n.name => n }

  filename = "${var.out_dir}/${each.value.name}-hostname.yaml"
  content = templatefile("${path.module}/templates/hostname.patch.yaml.tmpl", {
    fqdn = each.value.fqdn
  })
}


# Control plane machine configurations
data "talos_machine_configuration" "cp" {
  for_each = { for n in local.control_planes : n.name => n }

  cluster_name     = var.cluster_name
  cluster_endpoint = var.cluster_endpoint
  machine_type     = "controlplane"
  machine_secrets  = talos_machine_secrets.this.machine_secrets
  talos_version    = var.talos_version
}

# Worker machine configurations
data "talos_machine_configuration" "worker" {
  for_each = { for n in local.workers : n.name => n }

  cluster_name     = var.cluster_name
  cluster_endpoint = var.cluster_endpoint
  machine_type     = "worker"
  machine_secrets  = talos_machine_secrets.this.machine_secrets
  talos_version    = var.talos_version
}

# Apply control plane configurations
resource "talos_machine_configuration_apply" "cp" {
  for_each = { for n in local.control_planes : n.name => n }

  client_configuration        = talos_machine_secrets.this.client_configuration
  endpoint                    = proxmox_vm_qemu.nodes[each.key].default_ipv4_address
  node                        = proxmox_vm_qemu.nodes[each.key].default_ipv4_address
  machine_configuration_input = data.talos_machine_configuration.cp[each.key].machine_configuration
  config_patches              = [local_file.cp_cfg[each.key].content, local_file.cp_hostname_cfg[each.key].content]

  depends_on = [proxmox_vm_qemu.nodes]
}

# Apply worker configurations
resource "talos_machine_configuration_apply" "worker" {
  for_each = { for n in local.workers : n.name => n }

  client_configuration        = talos_machine_secrets.this.client_configuration
  endpoint                    = proxmox_vm_qemu.nodes[each.key].default_ipv4_address
  node                        = proxmox_vm_qemu.nodes[each.key].default_ipv4_address
  machine_configuration_input = data.talos_machine_configuration.worker[each.key].machine_configuration
  config_patches              = [local_file.worker_cfg[each.key].content, local_file.worker_hostname_cfg[each.key].content]

  depends_on = [
    proxmox_vm_qemu.nodes,
    talos_machine_bootstrap.this # Workers need cluster to be bootstrapped first
  ]
}

resource "null_resource" "wait_bootstrap" {
  depends_on = [talos_machine_configuration_apply.cp]
  provisioner "local-exec" {
    command = <<EOT
      counter=0
      while [ $counter -lt 24 ] ; do
        if nc -z "${proxmox_vm_qemu.nodes["xd-c-1"].default_ipv4_address}" 50000 ; then
          sleep 30
          exit 0
        fi
        sleep 5
        counter=$(($counter + 1))
      done
      exit 1
    EOT
  }
}

resource "talos_machine_bootstrap" "this" {
  depends_on = [
    talos_machine_configuration_apply.cp,
    null_resource.wait_bootstrap
  ]
  endpoint             = local.control_planes[0].fqdn
  node                 = local.control_planes[0].fqdn
  client_configuration = talos_machine_secrets.this.client_configuration
}

resource "talos_cluster_kubeconfig" "kc" {
  client_configuration = talos_machine_secrets.this.client_configuration
  node                 = local.control_planes[0].fqdn
  depends_on           = [talos_machine_bootstrap.this]
}
