terraform {
  required_version = ">= 1.13"

  # Garage S3 on the NAS (https://s3.nas.net.ecksd.ee). Credentials via
  # AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY — never commit them.
  backend "s3" {
    bucket                      = "terraform-state"
    key                         = "xd-net/infra/terraform.tfstate"
    region                      = "garage"
    endpoints                   = { s3 = "https://s3.nas.net.ecksd.ee" }
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    use_path_style              = true
    use_lockfile                = true
  }

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
    null = {
      source  = "hashicorp/null"
      version = ">= 3.2.0"
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
