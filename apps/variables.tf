variable "kubeconfig_path" {
  type        = string
  description = "Path to kubeconfig for the target cluster. Keep in config.auto.tfvars if you have multiple clusters."
  default     = "../infra/_out/kubeconfig"
}

variable "git_repo_url" {
  type        = string
  description = "Git repo URL for ArgoCD (contains apps/ and secrets/ paths)"
  default     = "https://github.com/chaosk/xd-net-apps.git"
}

variable "git_revision" {
  type    = string
  default = "HEAD"
}

variable "git_path_apps" {
  type    = string
  default = "apps"
}

variable "git_path_secrets" {
  type    = string
  default = "secrets"
}

variable "argocd_service_type" {
  type        = string
  description = "ArgoCD server Service type (LoadBalancer/NodePort/ClusterIP)"
  default     = "ClusterIP"
}

variable "argocd_use_gateway_api" {
  type        = bool
  description = "Expose ArgoCD using Gateway API (Cilium Gateway). When true, ArgoCD service stays ClusterIP and Gateway/HTTPRoute are created."
  default     = true
}

variable "argocd_host" {
  type        = string
  description = "Hostname for ArgoCD HTTPRoute (e.g. argocd.example.com). Required when argocd_use_gateway_api=true."
  default     = "argocd.net.ecksd.ee"
}

variable "argocd_gateway_class_name" {
  type        = string
  description = "GatewayClass name to use (Cilium typically uses 'cilium')."
  default     = "cilium"
}

variable "argocd_tls_secret_name" {
  type        = string
  description = "Secret name in argocd namespace containing TLS cert/key for Gateway termination."
  default     = "argocd-tls"
}

variable "acme_cluster_issuer_name" {
  type        = string
  description = "cert-manager ClusterIssuer name used cluster-wide (Gateway API HTTP-01)."
  default     = "letsencrypt-prod"
}

variable "acme_server" {
  type        = string
  description = "ACME directory URL (Let's Encrypt prod/staging)."
  default     = "https://acme-v02.api.letsencrypt.org/directory"
}

variable "acme_email" {
  type        = string
  description = "Email used for ACME registration."
}

variable "vercel_api_token" {
  type        = string
  description = "Vercel API token used by cert-manager DNS01 webhook."
  sensitive   = true
}

# Synology NAS credentials
variable "synology_host" {
  type        = string
  description = "Synology NAS IP address or hostname"
}

variable "synology_port" {
  type        = number
  description = "Synology NAS port (usually 5000 for HTTP or 5001 for HTTPS)"
  default     = 5001
}

variable "synology_https" {
  type        = bool
  description = "Use HTTPS to connect to Synology NAS"
  default     = true
}

variable "synology_username" {
  type        = string
  description = "Synology NAS admin username"
  sensitive   = true
}

variable "synology_password" {
  type        = string
  description = "Synology NAS admin password"
  sensitive   = true
}
