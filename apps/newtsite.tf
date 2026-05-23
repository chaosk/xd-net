# NewtSite: Pangolin tunnel + annotation-only HTTPRoute discovery (pangolin-operator/site-ref).

locals {
  pangolin_operator_helm = (
    var.pangolin_operator_enabled
    && var.pangolin_operator_api_url != ""
    && var.pangolin_operator_org_id != ""
    && var.pangolin_operator_api_key != null
    && var.pangolin_operator_api_key != ""
  )
}

resource "kubernetes_manifest" "pangolin_newtsite" {
  count = local.pangolin_operator_helm ? 1 : 0

  manifest = {
    apiVersion = "pangolin.home-operations.com/v1alpha1"
    kind       = "NewtSite"
    metadata = {
      name = var.pangolin_newtsite_name
    }
    spec = {
      name = var.pangolin_newtsite_display_name
      type = "newt"
      newt = {
        image    = var.pangolin_newtsite_newt_image
        tag      = var.pangolin_newtsite_newt_tag
        replicas = 1
        logLevel = "INFO"
        resources = {
          requests = {
            cpu    = "50m"
            memory = "64Mi"
          }
          limits = {
            cpu    = "1"
            memory = "256Mi"
          }
        }
      }
      autoDiscover = {
        enableRouteDiscovery   = true
        enableServiceDiscovery = false
        ssl                    = true
      }
    }
  }

  depends_on = [helm_release.pangolin_operator]
}
