# chaosk/pangolin-operator (fork) — manages Pangolin sites, newt, and PublicResource CRs.
# Requires Integration API on the OCI edge (pangolin-edge: enable_integration_api = true).
# Watches Gateway API TCPRoute v1 — needs Gateway API ≥1.6 standard (or experimental 1.6 with v1 served).
# Do not apply this chart pin on Gateway API 1.5.x (TCPRoute is v1alpha2 only there).

locals {
  # Operator client appends /v1/...; strip a trailing /v1 if tfvars copied from older docs.
  pangolin_operator_api_url = trimsuffix(trimsuffix(var.pangolin_operator_api_url, "/"), "/v1")
}

resource "kubernetes_namespace_v1" "pangolin_operator" {
  count = var.pangolin_operator_enabled ? 1 : 0

  metadata {
    name = var.pangolin_operator_namespace
    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }
}

resource "helm_release" "pangolin_operator" {
  count = (
    var.pangolin_operator_enabled
    && var.pangolin_operator_api_url != ""
    && var.pangolin_operator_org_id != ""
    && var.pangolin_operator_api_key != null
    && var.pangolin_operator_api_key != ""
  ) ? 1 : 0

  name             = "pangolin-operator"
  chart            = "pangolin-operator"
  repository       = var.pangolin_operator_chart_repository
  version          = var.pangolin_operator_chart_version
  namespace        = kubernetes_namespace_v1.pangolin_operator[0].metadata[0].name
  create_namespace = false

  values = [
    yamlencode({
      pangolin = {
        apiUrl   = local.pangolin_operator_api_url
        endpoint = coalesce(var.pangolin_operator_endpoint, "")
        orgId    = var.pangolin_operator_org_id
        apiKey   = var.pangolin_operator_api_key
      }
      controller = {
        logLevel = var.pangolin_operator_log_level
      }
    }),
    yamlencode(var.pangolin_operator_extra_values),
  ]

  depends_on = [kubernetes_namespace_v1.pangolin_operator]
}
