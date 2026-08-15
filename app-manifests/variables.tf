variable "kubeconfig_path" {
  type        = string
  description = "Path to kubeconfig (same as apps/ — usually ../infra/_out/kubeconfig)."
  default     = "../infra/_out/kubeconfig"
}

variable "gateway_api_release" {
  type        = string
  description = "Gateway API release tag (standard channel). Must match Envoy Gateway compatibility matrix (v1.8.x → v1.5.1)."
  default     = "v1.5.1"
}

variable "install_gateway_api_crds" {
  type        = bool
  description = "Apply Gateway API standard CRDs via Terraform. Set false if they already exist (Cilium gatewayAPI, prior apply, etc.)."
  default     = true
}

variable "install_gateway_api_experimental_crds" {
  type        = bool
  description = "Apply Gateway API experimental TCPRoute CRD (v1alpha2). Required by pangolin-operator."
  default     = true
}

variable "cert_manager_release" {
  type        = string
  description = "cert-manager release tag (must match apps/ cert_manager_chart_version)."
  default     = "v1.21.0"
}

variable "prometheus_operator_release" {
  type        = string
  description = "Prometheus Operator release tag for stripped-down CRDs (ServiceMonitor, PodMonitor, etc.)."
  default     = "v0.92.1"
}

variable "argocd_release" {
  type        = string
  description = "Argo CD release tag; CRDs are taken from manifests/install.yaml for this tag."
  default     = "v3.5.1"
}

variable "envoy_gateway_release" {
  type        = string
  description = "Envoy Gateway Helm chart version for gateway-crds-helm (Envoy Gateway CRDs only, not Gateway API). Must match apps/envoy_gateway_version."
  default     = "v1.8.2"
}
