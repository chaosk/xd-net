terraform {
  required_version = ">= 1.13"
  required_providers {
    proxmox = {
      source  = "Telmate/proxmox"
      version = "3.0.2-rc07"
    }
    talos = {
      source  = "siderolabs/talos"
      version = ">= 0.11.0"
    }
    local = {
      source  = "hashicorp/local"
      version = ">= 2.8.0"
    }
  }
}

provider "proxmox" {
  pm_api_url      = var.pm_api_url
  pm_user         = var.pm_user
  pm_password     = var.pm_password
  pm_tls_insecure = var.pm_tls_insecure
  pm_timeout      = var.pm_timeout

  # Drop when provider's updated for PVE 9.0.3
  pm_minimum_permission_check = false
}

provider "talos" {}
