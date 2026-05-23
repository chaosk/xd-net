data "http" "gateway_api_standard" {
  count = var.install_gateway_api_crds ? 1 : 0

  url = "https://github.com/kubernetes-sigs/gateway-api/releases/download/${var.gateway_api_release}/standard-install.yaml"
}

# pangolin-operator watches gateway.networking.k8s.io/v1alpha2 TCPRoute (experimental channel).
data "http" "gateway_api_experimental_tcp_route" {
  count = var.install_gateway_api_experimental_crds ? 1 : 0

  url = "https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/${var.gateway_api_release}/config/crd/experimental/gateway.networking.k8s.io_tcproutes.yaml"
}

data "http" "cert_manager_crds" {
  url = "https://github.com/cert-manager/cert-manager/releases/download/${var.cert_manager_release}/cert-manager.crds.yaml"
}

# ServiceMonitor / PodMonitor / Prometheus — required by Envoy Gateway addons & other GitOps monitoring manifests.
data "http" "prometheus_operator_crds" {
  url = "https://github.com/prometheus-operator/prometheus-operator/releases/download/${var.prometheus_operator_release}/stripped-down-crds.yaml"
}

data "http" "argocd_install" {
  url = "https://raw.githubusercontent.com/argoproj/argo-cd/${var.argocd_release}/manifests/install.yaml"
}

locals {
  # Multi-doc YAML often has a leading comment-only chunk before the first --- (e.g. Gateway API
  # standard-install). yamldecode fails on comment-only fragments; skip via try().
  split_yaml_documents = merge(
    var.install_gateway_api_crds ? {
      (data.http.gateway_api_standard[0].response_body) = [
        for doc in [
          for part in split("\n---", data.http.gateway_api_standard[0].response_body) :
          try(yamldecode(trimspace(part)), null)
          if trimspace(part) != "" && trimspace(part) != "..."
        ] : doc if doc != null
      ]
    } : {},
    var.install_gateway_api_experimental_crds ? {
      (data.http.gateway_api_experimental_tcp_route[0].response_body) = [
        try(yamldecode(trimspace(data.http.gateway_api_experimental_tcp_route[0].response_body)), null)
      ]
    } : {},
    {
      (data.http.cert_manager_crds.response_body) = [
        for doc in [
          for part in split("\n---", data.http.cert_manager_crds.response_body) :
          try(yamldecode(trimspace(part)), null)
          if trimspace(part) != "" && trimspace(part) != "..."
        ] : doc if doc != null
      ]
    },
    {
      (data.http.prometheus_operator_crds.response_body) = [
        for doc in [
          for part in split("\n---", data.http.prometheus_operator_crds.response_body) :
          try(yamldecode(trimspace(part)), null)
          if trimspace(part) != "" && trimspace(part) != "..."
        ] : doc if doc != null
      ]
    },
  )

  gateway_standard_body       = try(data.http.gateway_api_standard[0].response_body, null)
  gateway_experimental_bodies = var.install_gateway_api_experimental_crds ? [data.http.gateway_api_experimental_tcp_route[0].response_body] : []

  gateway_docs = flatten([
    for body, docs in local.split_yaml_documents :
    docs
    if local.gateway_standard_body != null && body == local.gateway_standard_body
  ])

  gateway_experimental_docs = flatten([
    for body, docs in local.split_yaml_documents :
    docs
    if contains(local.gateway_experimental_bodies, body)
  ])

  cert_manager_docs = local.split_yaml_documents[data.http.cert_manager_crds.response_body]

  prometheus_operator_docs = local.split_yaml_documents[data.http.prometheus_operator_crds.response_body]

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
    for i, doc in concat(local.gateway_docs, local.gateway_experimental_docs) :
    "gateway-api/${try(doc.metadata.name, i)}" => doc
    if try(doc.kind, "") == "CustomResourceDefinition" && try(doc.metadata.name, null) != null
  }

  cert_manager_manifests = {
    for i, doc in local.cert_manager_docs :
    "cert-manager/${try(doc.metadata.name, i)}" => doc
    if try(doc.kind, "") == "CustomResourceDefinition" && try(doc.metadata.name, null) != null
  }

  prometheus_operator_manifests = {
    for i, doc in local.prometheus_operator_docs :
    "prometheus-operator/${try(doc.metadata.name, i)}" => doc
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
    local.prometheus_operator_manifests,
    local.argocd_manifests,
  )
}

resource "kubernetes_manifest" "cluster_manifest" {
  for_each = local.crd_manifests

  # Upstream CRD bundles may include a top-level status; kubernetes_manifest forbids it.
  manifest = { for k, v in each.value : k => v if k != "status" }
}
