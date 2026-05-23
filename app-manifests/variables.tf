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
  description = "cert-manager release tag (must match or exceed the chart version used in apps/)."
  default     = "v1.17.1"
}

variable "prometheus_operator_release" {
  type        = string
  description = "Prometheus Operator release tag for stripped-down CRDs (ServiceMonitor, PodMonitor, etc.)."
  default     = "v0.79.2"
}

variable "argocd_release" {
  type        = string
  description = "Argo CD release tag; CRDs are taken from manifests/install.yaml for this tag."
  default     = "v2.14.0"
}

variable "envoy_gateway_release" {
  type        = string
  description = "Envoy Gateway Helm chart version for gateway-crds-helm (Envoy Gateway CRDs only, not Gateway API)."
  default     = "v1.5.0"
}
