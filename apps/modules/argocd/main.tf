locals {
  sops_age_enabled      = trimspace(var.sops_age_key_file) != ""
  sops_age_keys_content = local.sops_age_enabled ? sensitive(trimspace(file(abspath(var.sops_age_key_file)))) : null

  dex_authentik_enabled = (
    trimspace(var.oidc_issuer) != "" &&
    trimspace(var.oidc_client_id) != "" &&
    trimspace(var.oidc_client_secret) != ""
  )

  rbac_policy_set = trimspace(var.rbac_policy_csv) != ""

  github_webhook_secret_set = trimspace(var.github_webhook_secret) != ""

  argocd_secret_extra = merge(
    local.dex_authentik_enabled ? { "dex.authentik.clientSecret" = var.oidc_client_secret } : {},
    local.github_webhook_secret_set ? { "webhook.github.secret" = var.github_webhook_secret } : {},
  )

  # Dex OIDC connector → Authentik (https://integrations.goauthentik.io/infrastructure/argocd/)
  dex_config_block = <<-EOT
connectors:
  - type: oidc
    id: authentik
    name: ${var.oidc_display_name}
    config:
      issuer: ${var.oidc_issuer}
      clientID: ${var.oidc_client_id}
      clientSecret: $dex.authentik.clientSecret
      redirectURI: ${var.external_url}/api/dex/callback
      insecureEnableGroups: true
      getUserInfo: false
      scopes:
${join("\n", [for s in var.oidc_requested_scopes : "        - ${s}"])}
EOT

  # CMP v2: repo-server talks to argocd-cmp-server over a Unix socket (…/plugins/sops.sock).
  # Ref: https://argo-cd.readthedocs.io/en/stable/operator-manual/config-management-plugins/#sidecar-plugin
  #
  # Default: Alpine + wget static sops into /tmp (writable as uid 999; no apk/root). Needs egress
  # to github.com. Override cmp_sops_sidecar_image to an image with sops preinstalled to skip download.
  cmp_sops_sidecar_bootstrap = <<-SCRIPT
set -e
if ! command -v sops >/dev/null 2>&1; then
  ARCH=$(uname -m)
  case "$ARCH" in aarch64|arm64) SOPS_U=arm64 ;; *) SOPS_U=amd64 ;; esac
  wget -qO /tmp/sops "https://github.com/getsops/sops/releases/download/v3.9.4/sops-v3.9.4.linux.$${SOPS_U}"
  chmod +x /tmp/sops
fi
export PATH="/tmp:$${PATH}"
exec /var/run/argocd/argocd-cmp-server
SCRIPT

  cmp_sops_sidecar = merge(
    {
      name            = "cmp-sops"
      image           = var.cmp_sops_sidecar_image
      imagePullPolicy = "IfNotPresent"
      command         = ["/bin/sh", "-c"]
      args            = [trimspace(local.cmp_sops_sidecar_bootstrap)]
      securityContext = {
        allowPrivilegeEscalation = false
        capabilities             = { drop = ["ALL"] }
        readOnlyRootFilesystem     = false
        runAsNonRoot               = true
        runAsUser                  = 999
        seccompProfile             = { type = "RuntimeDefault" }
      }
      volumeMounts = concat(
        [
          { name = "var-files", mountPath = "/var/run/argocd" },
          { name = "plugins", mountPath = "/home/argocd/cmp-server/plugins" },
          { name = "argocd-cmp-cm", mountPath = "/home/argocd/cmp-server/config/plugin.yaml", subPath = "sops.yaml" },
          { name = "cmp-tmp", mountPath = "/tmp" },
        ],
        local.sops_age_enabled ? [{ name = "sops-age", mountPath = "/var/sops-age", readOnly = true }] : []
      )
    },
    local.sops_age_enabled ? {
      env = [
        {
          name  = "SOPS_AGE_KEY_FILE"
          value = "/var/sops-age/keys.txt"
        }
      ]
    } : {}
  )

  argocd_configs = merge(
    {
      cm = merge(
        {},
        var.external_url != null ? { url = var.external_url } : {},
        local.dex_authentik_enabled ? { "dex.config" = local.dex_config_block } : {},
        # Global default for `kustomize build` (ApplicationSet template cannot set per-app
        # kustomize in kubernetes_manifest — CRD schema omits it). Required for Kustomize
        # helmCharts / HelmChartInflationGenerator (e.g. Authentik OCI chart).
        { "kustomize.buildOptions" = "--enable-helm" },
        # Homepage widget API token account (role:readonly in rbac policy.csv).
        { "accounts.homepage" = "apiKey" }
      )
      cmp = {
        create = true
        plugins = {
          sops = {
            generate = {
              # POSIX sh does not expand **; a literal "**/*.yaml" path breaks sops.
              # ARGOCD_APP_SOURCE_PATH is the repo-relative Application path (e.g. "secrets");
              # CMP runs generate with cwd already that directory — do not find under that name again
              # or paths become .../secrets/secrets/...
              command = ["/bin/sh", "-c"]
              args = [
                "set -e; first=1; find . -type f \\( -name '*.yaml' -o -name '*.yml' \\) | sort | while IFS= read -r f; do [ \"$first\" = 1 ] || printf '%s\\n' '---'; first=0; sops -d \"$f\"; done"
              ]
            }
          }
        }
      }
    },
    length(local.argocd_secret_extra) > 0 ? {
      secret = {
        extra = local.argocd_secret_extra
      }
    } : {},
    local.rbac_policy_set ? {
      rbac = {
        "policy.csv" = trimspace(var.rbac_policy_csv)
      }
    } : {}
  )

  repo_server_volumes = concat(
    [
      {
        name = "argocd-cmp-cm"
        configMap = {
          name = "argocd-cmp-cm"
        }
      },
      {
        name     = "cmp-tmp"
        emptyDir = {}
      }
    ],
    local.sops_age_enabled ? [
      {
        name = "sops-age"
        secret = {
          secretName = var.sops_age_secret_name
          # 256 (0400) = root-only read; cmp-sops runs as uid 999 → permission denied on SOPS_AGE_KEY_FILE.
          # 420 = 0644 so the mounted keys file is readable by non-root (still only inside this pod).
          defaultMode = 420
        }
      }
    ] : []
  )

  argocd_helm_values = merge(
    {
      crds = {
        install = false
      }
      configs = local.argocd_configs
      server = {
        extraArgs = ["--insecure"]
        service = {
          type = "ClusterIP"
        }
      }
      repoServer = {
        extraContainers = [local.cmp_sops_sidecar]
        volumes         = local.repo_server_volumes
      }
    },
    local.dex_authentik_enabled ? { dex = { enabled = true } } : {}
  )
}

resource "kubernetes_namespace_v1" "argocd" {
  metadata {
    name = var.namespace
  }
}

resource "kubernetes_secret_v1" "sops_age" {
  count = local.sops_age_enabled ? 1 : 0

  metadata {
    name      = var.sops_age_secret_name
    namespace = kubernetes_namespace_v1.argocd.metadata[0].name
  }

  # Provider base64-encodes `data` for the API; do not base64encode here (double-encoding
  # mounts garbage → sops: "malformed secret key: mixed case" on the base64 text).
  data = {
    "keys.txt" = local.sops_age_keys_content
  }

  depends_on = [kubernetes_namespace_v1.argocd]
}

resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = var.namespace
  create_namespace = false
  wait             = true

  values = [yamlencode(local.argocd_helm_values)]

  depends_on = [
    kubernetes_namespace_v1.argocd,
    kubernetes_secret_v1.sops_age,
  ]
}
