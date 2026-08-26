# CNPG-I Barman Cloud plugin (ObjectStore CRD, WAL archive + base backups).
# Docs: https://cloudnative-pg.io/plugin-barman-cloud/
# Requires cert-manager (already installed) for the plugin's TLS certificates.

resource "helm_release" "plugin_barman_cloud" {
  name             = "plugin-barman-cloud"
  chart            = "plugin-barman-cloud"
  repository       = "https://cloudnative-pg.github.io/charts"
  version          = var.cnpg_barman_plugin_chart_version
  namespace        = kubernetes_namespace_v1.cnpg_system.metadata[0].name
  create_namespace = false
  wait             = true
  timeout          = 600

  values = [
    yamlencode(merge(
      {
        crds = {
          create = true
        }
      },
      var.cnpg_barman_plugin_extra_values
    ))
  ]

  depends_on = [
    helm_release.cloudnative_pg,
    helm_release.certmanager,
  ]
}
