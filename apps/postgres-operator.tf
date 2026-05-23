# CloudNativePG operator (Cluster CRs, backups, failover). Docs: https://cloudnative-pg.io/

resource "kubernetes_namespace_v1" "cnpg_system" {
  metadata {
    name = var.cnpg_operator_namespace
  }
}

resource "helm_release" "cloudnative_pg" {
  name             = "cloudnative-pg"
  chart            = "cloudnative-pg"
  repository       = "https://cloudnative-pg.github.io/charts"
  version          = var.cnpg_operator_chart_version
  namespace        = kubernetes_namespace_v1.cnpg_system.metadata[0].name
  create_namespace = false
  wait             = true

  values = [
    yamlencode(merge(
      {
        crds = {
          create = true
        }
      },
      var.cnpg_operator_extra_values
    ))
  ]

  depends_on = [kubernetes_namespace_v1.cnpg_system]
}
