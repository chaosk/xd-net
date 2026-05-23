# DNS for Pangolin on Vercel (same API token as apps/ cert-manager DNS-01).

resource "vercel_dns_record" "pangolin_wildcard" {
  count = var.manage_vercel_dns && var.vercel_wildcard_dns ? 1 : 0

  domain  = var.pangolin_base_domain
  name    = "*"
  type    = "A"
  ttl     = var.vercel_dns_ttl
  value   = local.public_ip
  comment = "pangolin-edge Terraform: wildcard public HTTPS resources"

  team_id = var.vercel_team_id

  depends_on = [oci_core_public_ip.pangolin]
}

resource "vercel_dns_record" "pangolin_dashboard" {
  count = var.manage_vercel_dns && local.dashboard_dns_name != "*" ? 1 : 0

  domain  = var.pangolin_base_domain
  name    = local.dashboard_dns_name
  type    = "A"
  ttl     = var.vercel_dns_ttl
  value   = local.public_ip
  comment = "pangolin-edge Terraform: Pangolin dashboard + Gerbil endpoint"

  team_id = var.vercel_team_id

  depends_on = [oci_core_public_ip.pangolin]
}

resource "vercel_dns_record" "pangolin_integration_api" {
  count = (
    var.manage_vercel_dns
    && var.enable_integration_api
    && !var.vercel_wildcard_dns
    && local.integration_api_dns_name != ""
  ) ? 1 : 0

  domain  = var.pangolin_base_domain
  name    = local.integration_api_dns_name
  type    = "A"
  ttl     = var.vercel_dns_ttl
  value   = local.public_ip
  comment = "pangolin-edge Terraform: Integration API (pangolin-operator)"

  team_id = var.vercel_team_id

  depends_on = [oci_core_public_ip.pangolin]
}
