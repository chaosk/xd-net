terraform {
  required_version = ">= 1.11"

  # Garage S3 on the NAS (https://s3.nas.net.ecksd.ee). Credentials via
  # AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY — never commit them.
  backend "s3" {
    bucket                      = "terraform-state"
    key                         = "xd-net/pangolin-edge/terraform.tfstate"
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
    oci = {
      source  = "oracle/oci"
      version = ">= 6.0.0"
    }
    local = {
      source  = "hashicorp/local"
      version = ">= 2.5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.6.0"
    }
    null = {
      source  = "hashicorp/null"
      version = ">= 3.2.0"
    }
    time = {
      source  = "hashicorp/time"
      version = ">= 0.11.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = ">= 4.0.0"
    }
    vercel = {
      source  = "vercel/vercel"
      version = ">= 1.14.0"
    }
  }
}
