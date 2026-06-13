module "argocd" {
  source = "./modules/argocd"

  external_url           = "https://${var.argocd_host}"
  sops_age_key_file      = var.argocd_sops_age_key_file
  sops_age_secret_name   = var.argocd_sops_age_secret_name
  cmp_sops_sidecar_image = var.argocd_cmp_sops_sidecar_image

  oidc_issuer           = var.argocd_oidc_issuer
  oidc_client_id        = var.argocd_oidc_client_id
  oidc_client_secret    = var.argocd_oidc_client_secret
  oidc_display_name     = var.argocd_oidc_display_name
  oidc_requested_scopes = var.argocd_oidc_requested_scopes
  rbac_policy_csv         = var.argocd_rbac_policy_csv
  github_webhook_secret   = var.argocd_github_webhook_secret
}

