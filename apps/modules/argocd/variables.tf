variable "namespace" {
  type        = string
  description = "Namespace to install ArgoCD into."
  default     = "argocd"
}

variable "external_url" {
  type        = string
  description = "Public URL for Argo CD (e.g. https://argocd.example.com). Used for redirects and callback URLs."
  default     = null
}

variable "sops_age_key_file" {
  type        = string
  description = "Path to Age keys.txt; creates a Secret and mounts it into the cmp-sops sidecar (SOPS_AGE_KEY_FILE). Gitignore. Empty = no Secret/volume (SOPS decrypt in cluster will fail)."
  default     = ""
}

variable "sops_age_secret_name" {
  type        = string
  description = "Kubernetes Secret name in the Argo CD namespace holding keys.txt for SOPS_AGE_KEY_FILE."
  default     = "argo-sops-age"
}

variable "cmp_sops_sidecar_image" {
  type        = string
  description = "CMP sops sidecar base image (needs /bin/sh + wget for default bootstrap). Default alpine:3.20 — first start downloads static sops to /tmp (needs egress to github.com). Override with your own image if sops is preinstalled."
  default     = "docker.io/library/alpine:3.20"
}

variable "oidc_issuer" {
  type        = string
  description = "Authentik OIDC issuer (e.g. https://authentik.example.com/application/o/<slug>/). Empty disables Dex→Authentik connector."
  default     = ""
}

variable "oidc_client_id" {
  type        = string
  description = "OAuth2 client ID from Authentik. Empty disables Dex→Authentik connector."
  default     = ""
}

variable "oidc_client_secret" {
  type        = string
  description = "OAuth2 client secret; stored in argocd-secret as dex.authentik.clientSecret. Empty disables Dex→Authentik connector."
  default     = ""
  sensitive   = true
}

variable "oidc_display_name" {
  type        = string
  description = "Dex connector display name in Argo CD UI."
  default     = "Authentik"
}

variable "oidc_requested_scopes" {
  type        = list(string)
  description = "OIDC scopes passed to Authentik via Dex (include groups for RBAC mapping)."
  default     = ["openid", "profile", "email", "groups"]
}

variable "rbac_policy_csv" {
  type        = string
  description = "Optional argocd-rbac-cm policy.csv (e.g. g, ArgoCD Admins, role:admin). Empty leaves chart default."
  default     = ""
}

variable "github_webhook_secret" {
  type        = string
  description = "GitHub webhook HMAC secret for /api/webhook (argocd_webhook_host). Stored in argocd-secret as webhook.github.secret."
  default     = ""
  sensitive   = true
}

