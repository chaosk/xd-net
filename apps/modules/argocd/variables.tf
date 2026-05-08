variable "namespace" {
  type        = string
  description = "Namespace to install ArgoCD into."
  default     = "argocd"
}

variable "use_gateway_api" {
  type        = bool
  description = "Expose ArgoCD using Gateway API (Cilium Gateway)."
  default     = true
}

variable "host" {
  type        = string
  description = "Hostname for ArgoCD."
}

variable "service_type" {
  type        = string
  description = "ArgoCD server Service type when not using Gateway API."
  default     = "ClusterIP"
}

variable "gateway_class_name" {
  type        = string
  description = "GatewayClass name to use."
  default     = "cilium"
}

variable "tls_secret_name" {
  type        = string
  description = "TLS Secret name in the ArgoCD namespace used by the Gateway listener."
  default     = "argocd-tls"
}

variable "cluster_issuer_name" {
  type        = string
  description = "cert-manager ClusterIssuer name used to issue the Gateway certificate."
}

