variable "kubeconfig_path" {
  type        = string
  description = "Path to kubeconfig for the target cluster. Keep in config.auto.tfvars if you have multiple clusters."
  default     = "../infra/_out/kubeconfig"
}

variable "git_repo_url" {
  type        = string
  description = "Git repo URL for Argo CD (apps/ and secrets/). Use git@github.com:org/repo.git for SSH deploy keys."
  default     = "git@github.com:chaosk/xd-net-apps.git"
}

variable "git_repo_ssh_private_key" {
  type        = string
  description = "OpenSSH private key for git_repo_url when the repo is private (GitHub deploy key). Leave empty for public HTTPS/SSH without auth."
  default     = ""
  sensitive   = true
}

variable "git_repo_credentials_secret_name" {
  type        = string
  description = "Name of the repository Secret in the argocd namespace."
  default     = "repo-gitops"
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

variable "argocd_host" {
  type        = string
  description = "Hostname for ArgoCD (Gateway API HTTPRoute host)."
  default     = "argocd.net.ecksd.ee"
}

variable "argocd_sops_age_key_file" {
  type        = string
  description = "Path to Age private keys file for Argo CD SOPS CMP (SOPS_AGE_KEY_FILE). Gitignored by default (see apps/.gitignore). Empty = no Secret or mount. Use an absolute path or a path relative to the Terraform working directory (typically apps/)."
  default     = ""
}

variable "argocd_sops_age_secret_name" {
  type        = string
  description = "Secret name in argocd namespace for SOPS Age keys (keys.txt key)."
  default     = "argo-sops-age"
}

variable "argocd_cmp_sops_sidecar_image" {
  type        = string
  description = "CMP sops sidecar image. Default alpine:3.20 (bootstraps sops from GitHub into /tmp). Use your own image with sops on PATH to avoid that download."
  default     = "docker.io/library/alpine:3.20"
}

variable "argocd_oidc_issuer" {
  type        = string
  description = "Authentik OIDC issuer URL. Set together with client_id and client_secret to add a Dex OIDC connector (bundled Dex stays enabled)."
  default     = ""
}

variable "argocd_oidc_client_id" {
  type        = string
  description = "OAuth2 client ID from Authentik (Dex connector)."
  default     = ""
}

variable "argocd_oidc_client_secret" {
  type        = string
  description = "OAuth2 client secret from Authentik; stored in argocd-secret as dex.authentik.clientSecret."
  default     = ""
  sensitive   = true
}

variable "argocd_oidc_display_name" {
  type        = string
  description = "Dex connector display name in the Argo CD UI."
  default     = "Authentik"
}

variable "argocd_oidc_requested_scopes" {
  type        = list(string)
  description = "OIDC scopes for the Dex→Authentik connector (include groups for RBAC)."
  default     = ["openid", "profile", "email", "groups"]
}

variable "argocd_rbac_policy_csv" {
  type        = string
  description = "Optional argocd-rbac-cm policy.csv (e.g. g, ArgoCD Admins, role:admin). Often required when using OIDC groups."
  default     = ""
}

variable "gateway_namespace" {
  type        = string
  description = "Namespace for the shared Gateway API Gateway."
  default     = "gateway"
}

variable "gateway_name" {
  type        = string
  description = "Name of the shared Gateway API Gateway."
  default     = "shared"
}

variable "gateway_class_name" {
  type        = string
  description = "GatewayClass for the shared Gateway (Envoy Gateway Helm chart installs 'eg')."
  default     = "eg"
}

variable "envoy_gateway_version" {
  type        = string
  description = "Envoy Gateway Helm chart version (gateway-helm + gateway-crds-helm OCI tags)."
  default     = "v1.5.0"
}

variable "envoy_gateway_namespace" {
  type        = string
  description = "Namespace for the Envoy Gateway control plane."
  default     = "envoy-gateway-system"
}

variable "envoy_gateway_controller_replicas" {
  type        = number
  description = "Envoy Gateway controller deployment replicas."
  default     = 1
}

variable "envoy_gateway_controller_cpu_request" {
  type        = string
  description = "Envoy Gateway controller CPU request (Helm deployment.envoyGateway.resources)."
  default     = "100m"
}

variable "envoy_gateway_controller_cpu_limit" {
  type        = string
  description = "Envoy Gateway controller CPU limit."
  default     = "500m"
}

variable "envoy_gateway_controller_memory_request" {
  type        = string
  description = "Envoy Gateway controller memory request."
  default     = "256Mi"
}

variable "envoy_gateway_controller_memory_limit" {
  type        = string
  description = "Envoy Gateway controller memory limit."
  default     = "512Mi"
}

variable "envoy_proxy_config_name" {
  type        = string
  description = "EnvoyProxy CR name referenced by the shared Gateway (infrastructure.parametersRef)."
  default     = "shared-proxy"
}

variable "envoy_proxy_replicas" {
  type        = number
  description = "Envoy proxy Deployment replicas for the shared Gateway."
  default     = 1
}

variable "envoy_proxy_cpu_request" {
  type        = string
  description = "Envoy proxy (dataplane) CPU request."
  default     = "100m"
}

variable "envoy_proxy_cpu_limit" {
  type        = string
  description = "Envoy proxy CPU limit (L7 + ext-auth spikes)."
  default     = "2000m"
}

variable "envoy_proxy_memory_request" {
  type        = string
  description = "Envoy proxy memory request."
  default     = "128Mi"
}

variable "envoy_proxy_memory_limit" {
  type        = string
  description = "Envoy proxy memory limit — caps proxy RAM so OOM kills the pod, not the node."
  default     = "1Gi"
}

variable "envoy_proxy_external_traffic_policy" {
  type        = string
  description = "Envoy Gateway proxy Service externalTrafficPolicy. Use Cluster with Cilium L2 (leader may differ from the Envoy pod node); Local only works if the L2 announcer and endpoints share the same node."
  default     = "Cluster"

  validation {
    condition     = contains(["Cluster", "Local"], var.envoy_proxy_external_traffic_policy)
    error_message = "envoy_proxy_external_traffic_policy must be Cluster or Local."
  }
}

variable "gateway_http_to_https_redirect" {
  type        = bool
  description = "Attach a catch-all HTTPRoute on listener http that 301/302 redirects to HTTPS."
  default     = true
}

variable "gateway_http_redirect_status_code" {
  type        = number
  description = "HTTP redirect status code (301 or 302)."
  default     = 301

  validation {
    condition     = contains([301, 302], var.gateway_http_redirect_status_code)
    error_message = "gateway_http_redirect_status_code must be 301 or 302."
  }
}

variable "gateway_tls_secret_name" {
  type        = string
  description = "TLS Secret name in the Gateway namespace used for termination."
  default     = "wildcard-tls"
}

variable "gateway_tls_dns_names" {
  type        = list(string)
  description = "DNS names for the shared Gateway TLS certificate (must cover all app hostnames)."
  default     = ["net.ecksd.ee", "*.net.ecksd.ee"]
}

variable "cilium_l2_loadbalancer_ip_pool" {
  type = object({
    start = string
    stop  = string
  })
  description = "Unused contiguous IPs on the same L2 as nodes for Envoy Gateway LoadBalancer (EXTERNAL-IP). Example: start = \"192.168.1.240\", stop = \"192.168.1.250\". If null, no pool is created and EXTERNAL-IP stays pending."
  default     = null
}

variable "cilium_l2_announcement_interfaces" {
  type        = list(string)
  description = "Optional interface names/patterns for L2 announcement (e.g. [\"eth0\"]). Empty = Cilium auto-detect."
  default     = []
}

variable "cilium_agent_memory_request" {
  type        = string
  description = "cilium-agent DaemonSet memory request (Helm resources.requests.memory)."
  default     = "256Mi"
}

variable "cilium_agent_memory_limit" {
  type        = string
  description = "cilium-agent DaemonSet memory limit — caps agent RAM so OOM kills the pod, not the node."
  default     = "1Gi"
}

variable "cilium_agent_cpu_request" {
  type        = string
  description = "cilium-agent DaemonSet CPU request."
  default     = "100m"
}

variable "cilium_agent_cpu_limit" {
  type        = string
  description = "cilium-agent DaemonSet CPU limit (BPF regen spikes)."
  default     = "2000m"
}

variable "cilium_init_memory_request" {
  type        = string
  description = "cilium-agent init container memory request (config / BPF template)."
  default     = "128Mi"
}

variable "cilium_init_memory_limit" {
  type        = string
  description = "cilium-agent init container memory limit."
  default     = "512Mi"
}

variable "cilium_operator_memory_request" {
  type        = string
  description = "cilium-operator Deployment memory request."
  default     = "128Mi"
}

variable "cilium_operator_memory_limit" {
  type        = string
  description = "cilium-operator Deployment memory limit."
  default     = "256Mi"
}

variable "cilium_operator_cpu_request" {
  type        = string
  description = "cilium-operator Deployment CPU request."
  default     = "50m"
}

variable "cilium_operator_cpu_limit" {
  type        = string
  description = "cilium-operator Deployment CPU limit."
  default     = "500m"
}

variable "cilium_hubble_relay_memory_request" {
  type        = string
  description = "hubble-relay memory request."
  default     = "64Mi"
}

variable "cilium_hubble_relay_memory_limit" {
  type        = string
  description = "hubble-relay memory limit."
  default     = "256Mi"
}

variable "cilium_hubble_ui_backend_memory_request" {
  type        = string
  description = "hubble-ui backend memory request."
  default     = "32Mi"
}

variable "cilium_hubble_ui_backend_memory_limit" {
  type        = string
  description = "hubble-ui backend memory limit."
  default     = "128Mi"
}

variable "cilium_hubble_ui_frontend_memory_request" {
  type        = string
  description = "hubble-ui frontend memory request."
  default     = "32Mi"
}

variable "cilium_hubble_ui_frontend_memory_limit" {
  type        = string
  description = "hubble-ui frontend memory limit."
  default     = "64Mi"
}

variable "acme_cluster_issuer_name" {
  type        = string
  description = "cert-manager ClusterIssuer name used cluster-wide (DNS-01 via Vercel)."
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

variable "acme_dns01_recursive_nameservers" {
  type        = list(string)
  description = "Optional DNS servers for cert-manager DNS-01 self-checks via controller --dns01-recursive-nameservers (host:port list). Set on Helm extraArgs, not ClusterIssuer (avoids Terraform CRD schema drift)."
  default     = []
}

variable "acme_dns01_recursive_nameservers_only" {
  type        = bool
  description = "If true and recursive nameservers are set, passes --dns01-recursive-nameservers-only to the controller. Use with public resolvers when Traefik-style disablePropagationCheck was needed (e.g. ISP blocks DNS to zone NS); cert-manager has no flag to skip self-checks entirely."
  default     = false
}

variable "vercel_api_token" {
  type        = string
  description = "Vercel API token used by cert-manager DNS01 webhook."
  sensitive   = true
}

variable "vercel_team_id" {
  type        = string
  description = "Optional Vercel Team ID (if your DNS zone is owned by a team)."
  default     = null
}

variable "vercel_team_slug" {
  type        = string
  description = "Optional Vercel Team slug (if your DNS zone is owned by a team)."
  default     = null
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

# Rancher local-path-provisioner (hostPath PVs; use for NVMe-backed dirs on nodes)
variable "local_path_chart_version" {
  type        = string
  description = "Helm chart version for oci://ghcr.io/rancher/local-path-provisioner/charts/local-path-provisioner"
  default     = "0.0.35"
}

variable "local_path_storage_class_name" {
  type        = string
  description = "StorageClass name created by local-path-provisioner"
  default     = "local-path"
}

variable "local_path_default_path" {
  type        = string
  description = "Host directory for volumes on nodes not listed in local_path_per_node_paths. With Talos UserVolumeConfig `local-path-data`, use /var/mnt/local-path-data (see infra/patches/local-path-user-volume.yaml.tmpl)."
  default     = "/var/mnt/local-path-data"
}

variable "local_path_per_node_paths" {
  type        = map(list(string))
  description = "Optional map of kubernetes.io/hostname value -> absolute host paths for provisioning on those nodes only. Example: { \"k8s-worker-a\" = [\"/var/local/nvme/local-path\"] }"
  default     = {}
}

# Intel GPU device plugins (in-cluster; GPU PCI passthrough stays in infra/ Proxmox VM config).
# Node Feature Discovery + intel-device-plugins-operator + intel-device-plugins-gpu are always installed from this stack.
variable "intel_gpu_device_plugins_namespace" {
  type        = string
  description = "Namespace for Intel device plugin Helm releases"
  default     = "intel-device-plugins-system"
}

variable "intel_gpu_operator_chart_version" {
  type        = string
  description = "Helm chart version for intel-device-plugins-operator"
  default     = "0.35.0"
}

variable "intel_gpu_plugin_chart_version" {
  type        = string
  description = "Helm chart version for intel-device-plugins-gpu (GpuDevicePlugin CR)"
  default     = "0.35.0"
}

variable "intel_gpu_plugin_resource_name" {
  type        = string
  description = "metadata.name of the GpuDevicePlugin CR"
  default     = "gpudeviceplugin-sample"
}

variable "intel_gpu_plugin_shared_dev_num" {
  type        = number
  description = "GpuDevicePlugin sharedDevNum: how many pods can share one GPU device node (Intel chart default is 1). Raise for multiple workloads on the same physical GPU."
  default     = 4
}

variable "node_feature_discovery_namespace" {
  type        = string
  description = "Namespace for node-feature-discovery (NFD) master/worker"
  default     = "node-feature-discovery"
}

variable "node_feature_discovery_chart_version" {
  type        = string
  description = "Helm chart version for nfd/node-feature-discovery"
  default     = "0.18.3"
}

variable "node_feature_discovery_extra_values" {
  type        = map(any)
  description = "Extra Helm values merged into node-feature-discovery (e.g. worker tolerations)"
  default     = {}
}

variable "intel_gpu_plugin_extra_values" {
  type        = map(any)
  description = "Extra Helm values merged into intel-device-plugins-gpu (chart defaults apply for nodeSelector; override here if needed)."
  default     = {}
}

# CloudNativePG operator (PostgreSQL clusters via Cluster CRD)
variable "cnpg_operator_namespace" {
  type        = string
  description = "Namespace for the CloudNativePG operator (Helm release cloudnative-pg)"
  default     = "cnpg-system"
}

variable "cnpg_operator_chart_version" {
  type        = string
  description = "Helm chart version for cnpg/cloudnative-pg (https://cloudnative-pg.github.io/charts)"
  default     = "0.28.1"
}

variable "cnpg_operator_extra_values" {
  type        = map(any)
  description = "Extra Helm values merged into cloudnative-pg (e.g. config.clusterWide, monitoring, nodeSelector)"
  default     = {}
}

# pangolin-operator (https://github.com/home-operations/pangolin-operator)
variable "pangolin_operator_enabled" {
  type        = bool
  description = "Install pangolin-operator Helm chart (requires OCI edge Integration API + org API key)."
  default     = false
}

variable "pangolin_operator_namespace" {
  type        = string
  description = "Namespace for pangolin-operator controller and CRDs."
  default     = "pangolin-operator"
}

variable "pangolin_operator_chart_version" {
  type        = string
  description = "Helm chart version (oci://ghcr.io/home-operations/charts/pangolin-operator)."
  default     = "0.1.4"
}

variable "pangolin_operator_api_url" {
  type        = string
  description = "Integration API base URL without path (pangolin-edge output integration_api_url). Do not include /v1 — the operator adds it."
  default     = ""
}

variable "pangolin_operator_endpoint" {
  type        = string
  description = "Pangolin dashboard URL for newt (pangolin-edge output pangolin_operator_endpoint)."
  default     = null
}

variable "pangolin_operator_org_id" {
  type        = string
  description = "Pangolin organization ID from the dashboard."
  default     = ""
}

variable "pangolin_operator_api_key" {
  type        = string
  description = "Pangolin Integration API org key (sensitive; create in dashboard)."
  default     = null
  sensitive   = true
}

variable "pangolin_operator_log_level" {
  type        = string
  description = "Controller log level."
  default     = "info"
}

variable "pangolin_operator_extra_values" {
  type        = map(any)
  description = "Extra Helm values merged into pangolin-operator."
  default     = {}
}

variable "pangolin_newtsite_name" {
  type        = string
  description = "Cluster-scoped NewtSite resource name (pangolin-operator/site-ref annotation value)."
  default     = "xd-net"
}

variable "pangolin_newtsite_display_name" {
  type        = string
  description = "Pangolin dashboard display name for the site."
  default     = "xd-net k8s cluster"
}

variable "pangolin_newtsite_newt_image" {
  type        = string
  description = "newt container image repository."
  default     = "ghcr.io/fosrl/newt"
}

variable "pangolin_newtsite_newt_tag" {
  type        = string
  description = "newt container image tag."
  default     = "1.12.5"
}
