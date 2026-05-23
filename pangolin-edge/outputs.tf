output "public_ip" {
  description = "Reserved public IPv4 — point DNS A records here."
  value       = local.public_ip
}

output "instance_ocid" {
  description = "Compute instance OCID."
  value       = oci_core_instance.pangolin.id
}

output "instance_vnic_id" {
  description = "Primary VNIC OCID."
  value       = local.primary_vnic_id
}

output "compartment_id" {
  description = "Compartment OCID."
  value       = local.compartment_id
}

output "subnet_id" {
  description = "Public subnet OCID."
  value       = local.subnet_id
}

output "vcn_id" {
  description = "VCN OCID."
  value       = local.vcn_id
}

output "dashboard_url" {
  description = "Pangolin dashboard after install."
  value       = "https://${var.pangolin_dashboard_host}"
}

output "initial_setup_url" {
  description = "First-time admin setup URL."
  value       = "https://${var.pangolin_dashboard_host}/auth/initial-setup"
}

output "pangolin_setup_token" {
  description = "One-time Pangolin initial-setup token (written during terraform apply when install_pangolin_via_ssh is true). terraform output -raw pangolin_setup_token"
  value       = local.pangolin_setup_token
  sensitive   = true
}

output "dns_checklist_path" {
  description = "Generated DNS checklist (_out/dns-checklist.txt)."
  value       = local_file.dns_checklist.filename
}

output "required_firewall_ports" {
  description = "Ports opened on the subnet security list (and UFW when install runs)."
  value = {
    tcp = [22, 80, 443]
    udp = [51820, 21820]
  }
}

output "deploy_bundle_path" {
  description = "Rendered Docker Compose stack."
  value       = var.generate_deploy_bundle ? local.deploy_dir : null
}

output "pangolin_server_secret" {
  description = "server.secret in config.yml (sensitive; in Terraform state)."
  value       = var.generate_deploy_bundle ? random_password.pangolin_secret[0].result : null
  sensitive   = true
}

output "push_deploy_command" {
  description = "Re-run deploy without Terraform SSH (e.g. after config change)."
  value       = var.generate_deploy_bundle ? "./scripts/push-deploy.sh ${var.ssh_user}@${local.public_ip} ${var.remote_install_dir}" : null
}

output "ssh_private_key_path" {
  description = "Path to SSH private key file. Use: terraform output -raw ssh_private_key_path"
  value       = local.ssh_private_key_path_output
  sensitive   = true
}

output "ssh_public_key_path" {
  description = "Path to SSH public key file."
  value       = local.ssh_public_key_path_output
}

output "integration_api_url" {
  description = "Pangolin Integration API base URL for pangolin-operator (https://host, no /v1). REST paths are /v1/…; Swagger at /docs."
  value       = local.integration_api_url
}

output "pangolin_operator_endpoint" {
  description = "Pangolin URL for newt / PANGOLIN_ENDPOINT (dashboard / Gerbil)."
  value       = "https://${var.pangolin_dashboard_host}"
}

output "vercel_dns_records" {
  description = "Vercel DNS record names managed by Terraform."
  value = var.manage_vercel_dns ? compact([
    var.vercel_wildcard_dns ? "*.${var.pangolin_base_domain}" : null,
    local.dashboard_dns_name != "" ? "${local.dashboard_dns_name}.${var.pangolin_base_domain}" : var.pangolin_base_domain,
    var.enable_integration_api && !var.vercel_wildcard_dns && local.integration_api_dns_name != "" ? local.integration_api_host : null,
  ]) : []
}
