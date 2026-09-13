terraform {
  required_version = ">= 1.0"
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 3.2.1"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 3.3.0"
    }
    cilium = {
      source  = "littlejo/cilium"
      version = ">= 0.3.2"
    }
  }
}

provider "kubernetes" {
  config_path = var.kubeconfig_path
}

provider "helm" {
  kubernetes = {
    config_path = var.kubeconfig_path
  }
}

provider "cilium" {
  config_path = var.kubeconfig_path
}
