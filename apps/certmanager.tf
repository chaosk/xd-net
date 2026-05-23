locals {
  cert_manager_dns01_extra_args = concat(
    length(var.acme_dns01_recursive_nameservers) > 0 ? [
      "--dns01-recursive-nameservers=${join(",", var.acme_dns01_recursive_nameservers)}"
    ] : [],
    var.acme_dns01_recursive_nameservers_only && length(var.acme_dns01_recursive_nameservers) > 0 ? [
      "--dns01-recursive-nameservers-only=true"
    ] : [],
  )
}

resource "helm_release" "certmanager" {
  name             = "cert-manager"
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  namespace        = "cert-manager"
  create_namespace = true
  wait             = true

  values = [
    yamlencode({
      installCRDs = false
      podDnsConfig = {
        options = [
          {
            name  = "ndots"
            value = "1"
          }
        ]
      }
      config = {
        apiVersion       = "controller.config.cert-manager.io/v1alpha1"
        kind             = "ControllerConfiguration"
        enableGatewayAPI = true
      }
      extraArgs = local.cert_manager_dns01_extra_args
    })
  ]
}
