# ============================================
# PROXMOX CONFIGURATION
# ============================================

variable "pm_api_url" {
  type        = string
  description = "Proxmox API URL"
}

variable "pm_user" {
  type        = string
  description = "Proxmox user"
}

variable "pm_password" {
  type        = string
  sensitive   = true
  description = "Proxmox password"
}

variable "pm_tls_insecure" {
  type        = bool
  default     = true
  description = "Skip TLS verification"
}

variable "pm_node" {
  type        = string
  description = "Proxmox node name"
}

variable "pm_timeout" {
  type        = number
  default     = 1800
  description = "Proxmox API client timeout in seconds. Large ISO uploads via the provider often still fail; see proxmox_manage_talos_iso."
}

# ============================================
# VM CONFIGURATION
# ============================================

variable "vm_cores" {
  type        = number
  default     = 4
  description = "Number of CPU cores per VM"
}

variable "vm_control_plane_memory_mb" {
  type        = number
  default     = 4096
  description = "Memory allocation in MB for control plane VMs (xd-c-*)."

  validation {
    condition     = var.vm_control_plane_memory_mb >= 4096
    error_message = "Talos requires at least 4GB of RAM on control plane nodes."
  }
}

variable "vm_worker_memory_mb" {
  type        = number
  default     = 12288
  description = "Memory allocation in MB for worker VMs (xd-w-*)."

  validation {
    condition     = var.vm_worker_memory_mb >= 4096
    error_message = "Talos requires at least 4GB of RAM on worker nodes."
  }
}

variable "vm_disk_gb" {
  type        = number
  default     = 20
  description = "Disk size in GB"

  validation {
    condition     = var.vm_disk_gb >= 10
    error_message = "Disk size must be at least 10GB."
  }
}

variable "vm_worker_data_disk_gb" {
  type        = number
  default     = 500
  description = "Extra data disk size in GB on worker VMs only (xd-w-*, scsi1 / local-path). Control planes have no data disk."

  validation {
    condition     = var.vm_worker_data_disk_gb >= 50
    error_message = "Worker data disk must be at least 50GB."
  }
}

variable "vm_storage" {
  type        = string
  default     = "local-lvm"
  description = "Proxmox storage pool"
}

variable "vm_data_storage" {
  type        = string
  default     = "nvme_pool"
  description = "Proxmox storage pool for the extra data disk"
}

variable "vm_disk_cache" {
  type        = string
  default     = "none"
  description = "VM disk cache type (none/writeback)"
}

variable "vm_bridge" {
  type        = string
  default     = "vmbr1"
  description = "Network bridge"
}

# Monitoring & Performance
variable "enable_qemu_guest_agent" {
  type        = bool
  default     = true
  description = "Enable QEMU guest agent"
}

variable "vm_cpu_limit" {
  type        = number
  default     = 0
  description = "CPU limit (0 = unlimited)"
}

variable "vm_memory_ballooning" {
  type        = bool
  default     = true
  description = "Enable memory ballooning on worker VMs only (control planes always use balloon=0)."
}

# Network
variable "network_model" {
  type        = string
  default     = "virtio"
  description = "Network interface model"
}

variable "vm_vlan_id" {
  type        = number
  default     = null
  description = "VLAN ID for primary network"
}

# ============================================
# CLUSTER CONFIGURATION
# ============================================

variable "cluster_name" {
  type        = string
  default     = "xd-net"
  description = "Kubernetes cluster name"
}

variable "cluster_endpoint" {
  type        = string
  default     = "https://k8s.net.ecksd.ee:6443"
  description = "Kubernetes cluster endpoint"
}

variable "domain_suffix" {
  type        = string
  default     = "k8s.net.ecksd.ee"
  description = "Domain suffix for nodes"
}

variable "talos_version" {
  type        = string
  default     = "v1.13.0"
  description = "Talos version"
}

variable "talos_iso_url" {
  type        = string
  default     = "https://factory.talos.dev/image/79d80db11c7f0e8bc14aaf940e3b5dbde519e5c9e746b5d0751dd0487a2d5167/v1.13.0/metal-amd64-secureboot.iso"
  description = "Talos ISO download URL"
}

variable "talos_iso_name" {
  type        = string
  default     = "talos-1.13.0-metal-amd64-secureboot.iso"
  description = "Talos ISO filename"
}

# DNS
variable "dns_servers" {
  type        = list(string)
  default     = ["1.1.1.1", "8.8.8.8"]
  description = "DNS servers"
}

variable "search_domains" {
  type        = list(string)
  default     = []
  description = "DNS search domains"
}

variable "cluster_dns_ip" {
  type        = string
  default     = "10.96.0.10"
  description = "Cluster DNS service IP"
}

variable "service_subnet" {
  type        = string
  default     = "10.96.0.0/12"
  description = "Kubernetes service subnet"
}

variable "pod_subnet" {
  type        = string
  default     = "10.244.0.0/16"
  description = "Kubernetes pod subnet"
}

# ============================================
# SECURITY & NETWORKING
# ============================================

variable "enable_network_policies" {
  type        = bool
  default     = true
  description = "Enable network policies"
}

variable "default_deny_ingress" {
  type        = bool
  default     = true
  description = "Default deny ingress policy"
}

variable "default_deny_egress" {
  type        = bool
  default     = false
  description = "Default deny egress policy"
}

variable "allowed_ingress_namespaces" {
  type        = list(string)
  default     = ["kube-system", "traefik-system"]
  description = "Allowed ingress namespaces"
}

variable "monitoring_namespace" {
  type        = string
  default     = "monitoring"
  description = "Monitoring namespace"
}

# ============================================
# OUTPUT PATHS
# ============================================

variable "out_dir" {
  type        = string
  default     = "./_out"
  description = "Output directory for configs"
}
