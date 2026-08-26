terraform {
  required_version = ">= 1.11"

  # Garage S3 on the NAS (https://s3.nas.net.ecksd.ee). Credentials via
  # AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY — never commit them.
  backend "s3" {
    bucket                      = "terraform-state"
    key                         = "xd-net/app-manifests/terraform.tfstate"
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
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.38.0"
    }
    http = {
      source  = "hashicorp/http"
      version = ">= 3.4.0"
    }
  }
}

provider "kubernetes" {
  config_path = var.kubeconfig_path
}
