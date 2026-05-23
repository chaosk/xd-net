locals {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.pangolin.id
  subnet_id      = oci_core_subnet.pangolin_public.id
  public_ip      = oci_core_public_ip.pangolin.ip_address

  vnic_attachments = data.oci_core_vnic_attachments.instance.vnic_attachments

  primary_vnic_id = coalesce(
    try([for a in local.vnic_attachments : a.vnic_id if a.is_primary][0], null),
    local.vnic_attachments[0].vnic_id,
  )

  tunnel_host = coalesce(var.pangolin_tunnel_host, var.pangolin_dashboard_host)

  integration_api_host = (
    var.enable_integration_api
    ? coalesce(var.pangolin_integration_api_host, "pangolin-api.${var.pangolin_base_domain}")
    : null
  )
  # Operator appends /v1/... itself; Swagger is at https://<host>/docs (not /v1/docs).
  integration_api_url = local.integration_api_host != null ? "https://${local.integration_api_host}" : null

  # pangolin-api.ecksd.ee → "pangolin-api"; used when vercel_wildcard_dns is false
  integration_api_dns_name = (
    local.integration_api_host != null && local.integration_api_host != var.pangolin_base_domain
    ? replace(local.integration_api_host, ".${var.pangolin_base_domain}", "")
    : ""
  )

  # pangolin.ecksd.ee + base ecksd.ee → name "pangolin"; apex dashboard → ""
  dashboard_dns_name = (
    var.pangolin_dashboard_host == var.pangolin_base_domain
    ? ""
    : replace(var.pangolin_dashboard_host, ".${var.pangolin_base_domain}", "")
  )

  use_generated_ssh_key = var.ssh_public_key_path == null

  ssh_public_key_openssh = local.use_generated_ssh_key ? trimspace(tls_private_key.ssh[0].public_key_openssh) : trimspace(file(var.ssh_public_key_path))

  ssh_private_key_openssh = local.use_generated_ssh_key ? tls_private_key.ssh[0].private_key_openssh : file(var.ssh_private_key_path)

  ssh_private_key_path_output = local.use_generated_ssh_key ? abspath("${path.module}/_out/ssh/pangolin-edge") : abspath(var.ssh_private_key_path)
  ssh_public_key_path_output  = local.use_generated_ssh_key ? abspath("${path.module}/_out/ssh/pangolin-edge.pub") : abspath(var.ssh_public_key_path)
}
