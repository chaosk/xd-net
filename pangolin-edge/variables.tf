variable "oci_region" {
  type        = string
  description = "Oracle Cloud region (e.g. eu-frankfurt-1)."
}

variable "oci_config_profile" {
  type        = string
  description = "Profile name in ~/.oci/config (or OCI_CLI_CONFIG_FILE). Default profile if null."
  default     = null
}

variable "compartment_id" {
  type        = string
  description = "OCI compartment OCID for all resources in this stack."
}

variable "vcn_cidr" {
  type        = string
  description = "VCN CIDR."
  default     = "10.42.0.0/16"
}

variable "subnet_cidr" {
  type        = string
  description = "Public subnet CIDR (must fit in vcn_cidr)."
  default     = "10.42.0.0/24"
}

variable "instance_display_name" {
  type        = string
  description = "Compute instance display name."
  default     = "pangolin-edge"
}

variable "instance_shape" {
  type        = string
  description = "OCI shape. VM.Standard.A1.Flex (default) fits Always Free with more RAM for Pangolin/Gerbil/Traefik; E2.1.Micro is 1 GB and usually too tight."
  default     = "VM.Standard.A1.Flex"
}

variable "instance_ocpus" {
  type        = number
  description = "OCPUs when instance_shape is VM.Standard.A1.Flex (Always Free pool: 4 total)."
  default     = 4
}

variable "instance_memory_gbs" {
  type        = number
  description = "Memory (GB) when instance_shape is VM.Standard.A1.Flex (Always Free pool: 24 GB total)."
  default     = 24
}

variable "instance_os_version" {
  type        = string
  description = "Ubuntu LTS version for the platform image lookup (OCI platform image). Pangolin supports 22.04+; default is current LTS."
  default     = "24.04"
}

variable "boot_volume_size_gbs" {
  type        = number
  description = "Boot volume size (GB). 50 is a safe default for Ubuntu + Docker images; 5 GB is too small for Pangolin/Gerbil/Traefik."
  default     = 50
}

variable "availability_domain_index" {
  type        = number
  description = "Index into availability domains (0 = first AD in the region)."
  default     = 0
}

variable "ssh_public_key_path" {
  type        = string
  description = "Optional: use your own SSH public key file. If null, Terraform generates Ed25519 keys under _out/ssh/."
  default     = null
}

variable "ssh_private_key_path" {
  type        = string
  description = "Optional: private key file (required with ssh_public_key_path when install_pangolin_via_ssh is true)."
  default     = null
  sensitive   = true
}

variable "allow_ssh_cidr" {
  type        = string
  description = "CIDR allowed to SSH (subnet security list). Tighten from 0.0.0.0/0 when possible."
  default     = "0.0.0.0/0"
}

variable "pangolin_base_domain" {
  type        = string
  description = "Root domain for Pangolin (no subdomain), e.g. ecksd.ee."
}

variable "pangolin_dashboard_host" {
  type        = string
  description = "Dashboard FQDN, e.g. pangolin.ecksd.ee."
}

variable "pangolin_tunnel_host" {
  type        = string
  description = "Gerbil base_endpoint hostname (defaults to dashboard host)."
  default     = null
}

variable "letsencrypt_email" {
  type        = string
  description = "Email for Let's Encrypt and Pangolin admin."
}

variable "enable_integration_api" {
  type        = bool
  description = "Enable Pangolin Integration API (port 3003) and expose it via Traefik. Required for home-operations/pangolin-operator."
  default     = true
}

variable "pangolin_integration_api_host" {
  type        = string
  description = "FQDN for the Integration API (Traefik → pangolin:3003). Defaults to pangolin-api.<pangolin_base_domain> when enable_integration_api is true."
  default     = null
}

variable "pangolin_integration_port" {
  type        = number
  description = "Integration API listen port inside the pangolin container."
  default     = 3003
}

# --- Pangolin app (Docker Compose on the VM) ---

variable "generate_deploy_bundle" {
  type        = bool
  description = "Render _out/deploy/ from templates (config.yml, docker-compose.yml, Traefik)."
  default     = true
}

variable "pangolin_image_tag" {
  type        = string
  description = "fosrl/pangolin image tag (Community Edition)."
  default     = "latest"
}

variable "gerbil_image_tag" {
  type        = string
  description = "fosrl/gerbil image tag."
  default     = "latest"
}

variable "traefik_image_tag" {
  type        = string
  description = "Traefik image tag."
  default     = "v3.6"
}

variable "traefik_badger_version" {
  type        = string
  description = "Traefik badger plugin version."
  default     = "v1.3.1"
}

variable "enable_crowdsec" {
  type        = bool
  description = "Run CrowdSec with Traefik access-log acquisition and the Traefik bouncer plugin in front of Pangolin."
  default     = true
}

variable "crowdsec_image_tag" {
  type        = string
  description = "CrowdSec Docker image tag."
  default     = "latest-debian"
}

variable "traefik_crowdsec_bouncer_version" {
  type        = string
  description = "Traefik CrowdSec bouncer plugin version (github.com/maxlerebourg/crowdsec-bouncer-traefik-plugin)."
  default     = "v1.6.0"
}

variable "install_pangolin_via_ssh" {
  type        = bool
  description = "Copy deploy bundle to the VM and run docker compose up -d."
  default     = true
}

variable "ssh_user" {
  type        = string
  description = "SSH user (Ubuntu cloud images: ubuntu)."
  default     = "ubuntu"
}

variable "manage_vercel_dns" {
  type        = bool
  description = "Create/update A records on Vercel for the Pangolin public IP (wildcard + dashboard host)."
  default     = true
}

variable "vercel_api_token" {
  type        = string
  description = "Vercel API token (same as apps/ cert-manager DNS-01). Required when manage_vercel_dns is true."
  default     = null
  sensitive   = true
}

variable "vercel_team_id" {
  type        = string
  description = "Vercel team ID if the DNS zone is under a team."
  default     = null
}

variable "vercel_dns_ttl" {
  type        = number
  description = "TTL (seconds) for Vercel A records."
  default     = 300
}

variable "vercel_wildcard_dns" {
  type        = bool
  description = "Manage wildcard A record (*.) pointing at the Pangolin VM (public HTTPS resources)."
  default     = true
}

variable "remote_install_dir" {
  type        = string
  description = "Directory on the VM for the Pangolin compose stack."
  default     = "/opt/pangolin"
}
