# Envoy Gateway CRDs: cannot use kubernetes_manifest (yamldecode fails on OpenAPI schemas) or
# helm_release (rendered manifest exceeds the 1 MiB Helm release Secret limit).
# Upstream recommends: helm template | kubectl apply --server-side
# https://gateway.envoyproxy.io/latest/install/install-helm/#installing-crds-separately

resource "terraform_data" "envoy_gateway_crds" {
  input = {
    release    = var.envoy_gateway_release
    kubeconfig = abspath(var.kubeconfig_path)
  }

  provisioner "local-exec" {
    when    = create
    command = <<-EOT
      helm template envoy-gateway-crds oci://docker.io/envoyproxy/gateway-crds-helm \
        --version ${self.input.release} \
        --namespace envoy-gateway-system \
        --set crds.gatewayAPI.enabled=false \
        --set crds.envoyGateway.enabled=true \
        | kubectl --kubeconfig=${self.input.kubeconfig} apply --server-side --force-conflicts -f -
    EOT
  }

  # Destroy-time provisioners may only reference self.* (not locals/other resources).
  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      helm template envoy-gateway-crds oci://docker.io/envoyproxy/gateway-crds-helm \
        --version ${self.input.release} \
        --namespace envoy-gateway-system \
        --set crds.gatewayAPI.enabled=false \
        --set crds.envoyGateway.enabled=true \
        | kubectl --kubeconfig=${self.input.kubeconfig} delete --ignore-not-found -f -
    EOT
  }
}
