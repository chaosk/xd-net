variable "kubeconfig_path" {
  type        = string
  description = "Path to kubeconfig (same as apps/ — usually ../infra/_out/kubeconfig)."
  default     = "../infra/_out/kubeconfig"
}

variable "gateway_api_release" {
  type        = string
  description = "Gateway API release tag (standard channel)."
  default     = "v1.4.1"
}

variable "cert_manager_release" {
  type        = string
  description = "cert-manager release tag (must match or exceed the chart version used in apps/)."
  default     = "v1.17.1"
}

variable "argocd_release" {
  type        = string
  description = "Argo CD release tag; CRDs are taken from manifests/install.yaml for this tag."
  default     = "v2.14.0"
}
