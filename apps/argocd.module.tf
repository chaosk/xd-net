module "argocd" {
  source = "./modules/argocd"

  use_gateway_api     = var.argocd_use_gateway_api
  host                = var.argocd_host
  service_type              = var.argocd_service_type
  gateway_class_name        = var.argocd_gateway_class_name
  tls_secret_name           = var.argocd_tls_secret_name
  cluster_issuer_name       = var.acme_cluster_issuer_name
}

