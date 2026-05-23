resource "local_file" "dns_checklist" {
  content = templatefile("${path.module}/templates/dns-checklist.txt.tmpl", {
    public_ip              = local.public_ip
    base_domain            = var.pangolin_base_domain
    dashboard_host         = var.pangolin_dashboard_host
    tunnel_host            = local.tunnel_host
    letsencrypt_email      = var.letsencrypt_email
    integration_api_host   = local.integration_api_host
    integration_api_url    = local.integration_api_url
    enable_integration_api = var.enable_integration_api
  })
  filename             = "${path.module}/_out/dns-checklist.txt"
  file_permission      = "0644"
  directory_permission = "0755"
}
