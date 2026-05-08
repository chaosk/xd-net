resource "kubernetes_secret_v1" "vercel_api_token" {
  metadata {
    name      = "vercel-dns01-api-token"
    namespace = "cert-manager"
  }

  data = {
    token = var.vercel_api_token
  }

  depends_on = [helm_release.certmanager]
}

resource "helm_release" "cert_manager_webhook_vercel" {
  name      = "cert-manager-webhook-vercel"
  namespace = "cert-manager"

  # This project distributes its Helm chart as a versioned .tgz release artifact.
  chart = "https://github.com/rhythmbhiwani/cert-manager-webhook-vercel/releases/download/cert-manager-webhook-vercel-v1.0.0/cert-manager-webhook-vercel-v1.0.0.tgz"

  set = [
    {
      name  = "groupName"
      value = "acme.rhythmbhiwani.in"
    }
  ]

  depends_on = [helm_release.certmanager]
}

