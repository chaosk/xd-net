data "http" "gateway_api_standard" {
  url = "https://github.com/kubernetes-sigs/gateway-api/releases/download/${var.gateway_api_release}/standard-install.yaml"
}

data "http" "cert_manager_crds" {
  url = "https://github.com/cert-manager/cert-manager/releases/download/${var.cert_manager_release}/cert-manager.crds.yaml"
}

data "http" "argocd_install" {
  url = "https://raw.githubusercontent.com/argoproj/argo-cd/${var.argocd_release}/manifests/install.yaml"
}

locals {
  # Multi-doc YAML often has a leading comment-only chunk before the first --- (e.g. Gateway API
  # standard-install). yamldecode fails on comment-only fragments; skip via try().
  split_yaml_documents = { for raw in [
    data.http.gateway_api_standard.response_body,
    data.http.cert_manager_crds.response_body,
    ] : raw => [
    for doc in [
      for part in split("\n---", raw) :
      try(yamldecode(trimspace(part)), null)
      if trimspace(part) != "" && trimspace(part) != "..."
    ] : doc if doc != null
  ] }

  gateway_docs      = local.split_yaml_documents[data.http.gateway_api_standard.response_body]
  cert_manager_docs = local.split_yaml_documents[data.http.cert_manager_crds.response_body]

  argocd_docs = [
    for doc in [
      for part in split("\n---", data.http.argocd_install.response_body) :
      try(yamldecode(trimspace(part)), null)
      if trimspace(part) != "" && trimspace(part) != "..."
    ] : doc if doc != null
  ]

  argocd_crd_docs = [
    for doc in local.argocd_docs :
    doc if try(doc.kind, "") == "CustomResourceDefinition"
  ]

  gateway_manifests = {
    for i, doc in local.gateway_docs :
    "gateway-api/${try(doc.kind, "unknown")}-${try(doc.metadata.name, i)}" => doc
    if try(doc.apiVersion, null) != null && try(doc.kind, null) != null
  }

  cert_manager_manifests = {
    for i, doc in local.cert_manager_docs :
    "cert-manager/${try(doc.metadata.name, i)}" => doc
    if try(doc.kind, "") == "CustomResourceDefinition" && try(doc.metadata.name, null) != null
  }

  argocd_manifests = {
    for i, doc in local.argocd_crd_docs :
    "argocd/${doc.metadata.name}" => doc
    if try(doc.metadata.name, null) != null
  }

  crd_manifests = merge(
    local.gateway_manifests,
    local.cert_manager_manifests,
    local.argocd_manifests,
  )
}

resource "kubernetes_manifest" "cluster_manifest" {
  for_each = local.crd_manifests

  # Upstream CRD bundles may include a top-level status; kubernetes_manifest forbids it.
  manifest = { for k, v in each.value : k => v if k != "status" }
}
