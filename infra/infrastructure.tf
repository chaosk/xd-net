# ============================================
# PROXMOX VMS & TALOS CONFIGURATION
# ============================================

locals {
  # UserVolumeConfig mounts at /var/mnt/local-path-data — keep in sync with apps `local_path_default_path`.
  talos_local_path_user_volume_patch = templatefile("${path.module}/patches/local-path-user-volume.yaml.tmpl", {
    data_disk_min_gib = var.vm_worker_data_disk_gb - 50
    data_disk_max_gib = var.vm_worker_data_disk_gb + 50
    max_size          = "${var.vm_worker_data_disk_gb - 20}GiB"
  })
  # searchDomains.disableDefault belongs on ResolverConfig, not machine.network.searchDomains.
  talos_resolver_search_domains_patch = file("${path.module}/patches/resolver-search-domains.yaml")
  talos_kubelet_node_ip_patch = file("${path.module}/patches/kubelet-node-ip.yaml")

  control_plane_names = { for n in local.control_planes : n.name => true }

  node_memory_mb = merge(
    { for n in local.control_planes : n.name => var.vm_control_plane_memory_mb },
    { for n in local.workers : n.name => var.vm_worker_memory_mb },
  )
}

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
  boot      = "order=scsi0;ide0" # disk first after install; ISO fallback for empty disk / recovery
  bios      = "ovmf"
  scsihw    = "virtio-scsi-pci"
  agent     = var.enable_qemu_guest_agent ? 1 : 0
  skip_ipv6 = true

  cpu {
    cores   = var.vm_cores
    sockets = 1
    limit   = var.vm_cpu_limit
  }

  memory  = local.node_memory_mb[each.key]
  balloon = !lookup(local.control_plane_names, each.key, false) && var.vm_memory_ballooning ? local.node_memory_mb[each.key] / 2 : 0

  # Boot ISO
  disk {
    slot = "ide0"
    type = "cdrom"
    iso  = "local:iso/${var.talos_iso_name}"
  }

  disk {
    slot    = "scsi0"
    type    = "disk"
    storage = var.vm_storage
    size    = "${var.vm_disk_gb}G"
    cache   = var.vm_disk_cache
  }

  # Extra data disk on workers only (nvme_pool → Talos UserVolumeConfig / local-path)
  dynamic "disk" {
    for_each = lookup(local.control_plane_names, each.key, false) ? [] : [1]
    content {
      slot    = "scsi1"
      type    = "disk"
      storage = var.vm_data_storage
      size    = "${var.vm_worker_data_disk_gb}G"
      cache   = var.vm_disk_cache
    }
  }

  # Network
  network {
    id      = 0
    model   = var.network_model
    bridge  = var.vm_bridge
    macaddr = each.value.macaddr
    tag     = var.vm_vlan_id
  }

  # IoT-with-internet VLAN (192.168.2.0/24) for Multus macvlan on workers (Home Assistant).
  dynamic "network" {
    for_each = !lookup(local.control_plane_names, each.key, false) && var.worker_iot_vlan_id != null ? [1] : []
    content {
      id      = 1
      model   = var.network_model
      bridge  = var.vm_bridge
      macaddr = each.value.iot_macaddr
      tag     = var.worker_iot_vlan_id
    }
  }

  # GPU passthrough for specified nodes
  dynamic "pci" {
    for_each = each.value.gpu ? [1] : []
    content {
      id            = 0 # hostpci0 (provider requires number, not "pci0")
      mapping_id    = "arc_a310"
      pcie          = false
      primary_gpu   = false
      rombar        = false
      vendor_id     = "8086"
      device_id     = "56a6"
      sub_vendor_id = "4019"
      sub_device_id = "172f"
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
    talos_version   = var.talos_version
    install_disk    = "/dev/sda"
    enable_i915     = each.value.gpu
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
    talos_version   = var.talos_version
    install_disk    = "/dev/sda"
    enable_i915     = each.value.gpu
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

# Merged worker config (base + patches) for maintenance-mode recovery:
# talosctl --insecure apply-config -n <ip> -f _out/<name>-worker-full.yaml
data "talos_machine_configuration" "worker_full" {
  for_each = { for n in local.workers : n.name => n }

  cluster_name     = var.cluster_name
  cluster_endpoint = var.cluster_endpoint
  machine_type     = "worker"
  machine_secrets  = talos_machine_secrets.this.machine_secrets
  talos_version    = var.talos_version
  config_patches = concat([
    local_file.worker_cfg[each.key].content,
    local_file.worker_hostname_cfg[each.key].content,
    local.talos_local_path_user_volume_patch,
    local.talos_resolver_search_domains_patch,
    local.talos_kubelet_node_ip_patch,
  ], var.worker_iot_vlan_id != null ? [templatefile("${path.module}/patches/worker-iot-nic.yaml.tmpl", {
    iot_macaddr = each.value.iot_macaddr
  })] : [])
}

resource "local_file" "worker_full_cfg" {
  for_each = { for n in local.workers : n.name => n }

  filename = "${var.out_dir}/${each.value.name}-worker-full.yaml"
  content  = data.talos_machine_configuration.worker_full[each.key].machine_configuration

  depends_on = [
    local_file.worker_cfg,
    local_file.worker_hostname_cfg,
  ]
}

# Apply control plane configurations
resource "talos_machine_configuration_apply" "cp" {
  for_each = { for n in local.control_planes : n.name => n }

  client_configuration = talos_machine_secrets.this.client_configuration
  # Use stable FQDNs (known at plan time). Proxmox `default_ipv4_address` can appear
  # only during apply and triggers Talos provider "inconsistent final plan" on machine_configuration.
  endpoint                    = each.value.fqdn
  node                        = each.value.fqdn
  machine_configuration_input = data.talos_machine_configuration.cp[each.key].machine_configuration
  config_patches = [
    local_file.cp_cfg[each.key].content,
    local_file.cp_hostname_cfg[each.key].content,
    local.talos_resolver_search_domains_patch,
    local.talos_kubelet_node_ip_patch,
  ]

  depends_on = [proxmox_vm_qemu.nodes]
}

# Apply worker configurations
resource "talos_machine_configuration_apply" "worker" {
  for_each = { for n in local.workers : n.name => n }

  client_configuration = talos_machine_secrets.this.client_configuration
  endpoint                    = each.value.fqdn
  node                        = each.value.fqdn
  machine_configuration_input = data.talos_machine_configuration.worker[each.key].machine_configuration
  config_patches = concat([
    local_file.worker_cfg[each.key].content,
    local_file.worker_hostname_cfg[each.key].content,
    local.talos_local_path_user_volume_patch,
    local.talos_resolver_search_domains_patch,
    local.talos_kubelet_node_ip_patch,
  ], var.worker_iot_vlan_id != null ? [templatefile("${path.module}/patches/worker-iot-nic.yaml.tmpl", {
    iot_macaddr = each.value.iot_macaddr
  })] : [])

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
