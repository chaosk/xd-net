# xd-net

Terraform for the **xd-net** Kubernetes cluster: Talos on Proxmox VE, Cilium, cert-manager, Envoy Gateway, Argo CD, Synology CSI, and the Pangolin edge on Oracle Cloud. Workloads live in **[xd-net-apps](https://github.com/chaosk/xd-net-apps)** and sync via Argo CD.

API endpoint: **https://k8s.net.ecksd.ee:6443**. Argo CD UI: **https://argocd.net.ecksd.ee**. Shared Gateway TLS covers `net.ecksd.ee` / `*.net.ecksd.ee`.

## Layout

| Path | Role |
|------|------|
| `infra/` | Proxmox VMs + Talos bootstrap. Writes `infra/_out/kubeconfig` and `infra/_out/talosconfig`. |
| `app-manifests/` | Cluster CRDs (Gateway API, cert-manager, Prometheus Operator, Argo CD) and Envoy Gateway CRDs. Apply before `apps/`. |
| `apps/` | Platform: Cilium, cert-manager, Envoy Gateway, Argo CD (+ SOPS CMP), Synology CSI, Multus, CNPG operator, pangolin-operator / NewtSite. |
| `pangolin-edge/` | OCI VCN + VM + Pangolin/Gerbil/Traefik/CrowdSec. Homelab tunnels via Newt. See `pangolin-edge/README.md`. |
| [xd-net-apps](https://github.com/chaosk/xd-net-apps) | GitOps apps + SOPS secrets. |

Local secrets and tokens live in gitignored `config.auto.tfvars` under each stack (`infra/`, `apps/`, `pangolin-edge/`).

## Apply

Order matters: infra → CRDs → platform → (edge / apps repo already wired).

```bash
cd infra && terraform init && terraform apply

cd ../app-manifests && terraform init && terraform apply

cd ../apps && terraform init && terraform apply
```

Kubeconfig after infra:

```bash
export KUBECONFIG=infra/_out/kubeconfig
kubectl get nodes -o wide
```

## Argo CD / GitOps

Terraform in `apps/` points Argo CD at `git@github.com:chaosk/xd-net-apps.git`:

- **Application `platform-secrets`** — syncs `secrets/` with the SOPS CMP (Age key from `apps/sops.age.keys.txt`).
- **ApplicationSet `apps`** — one Application per `apps/*` directory in xd-net-apps.
- **Image Updater** — tag write-back for apps listed in xd-net-apps `apps/argocd-image-updater/image-updater.yaml`; git/signing/GHCR secrets are created in the `argocd` namespace.

GitHub webhook URL: **https://argocd.ecksd.ee/api/webhook** (Pangolin path; secret in `apps/config.auto.tfvars`).

Dex authenticates against Authentik at `https://authentik.net.ecksd.ee/application/o/argocd/`.

## Networking notes

- Cilium: kube-proxy replacement, L2 announcements on `ens18`, LB pool `192.168.4.201–210`. Gateway dataplane pinned to worker **`xd-w-2`** (`externalTrafficPolicy: Local`).
- Multus + macvlan for IoT VLAN on worker `ens19` (Cilium stays on `ens18` only).
- Synology CSI talks to `nas.net.ecksd.ee`.

## Git hooks

Commits must be [GPG-signed](https://git-scm.com/book/en/v2/Git-Tools-Signing-Your-Work). [pre-commit](https://pre-commit.com/) runs [require-signed-commits](https://github.com/pre-commit-garage/pre-commit-metadata-hooks) on `git push` and rejects any commit missing a `gpgsig` header.

```bash
brew install pre-commit
pre-commit install
git config commit.gpgsign true
```

## Talos image factory

Schematic ID: `79d80db11c7f0e8bc14aaf940e3b5dbde519e5c9e746b5d0751dd0487a2d5167`

```
customization:
    systemExtensions:
        officialExtensions:
            - siderolabs/amd-ucode
            - siderolabs/i915
            - siderolabs/iscsi-tools
            - siderolabs/qemu-guest-agent
```

Talos version and ISO URL are pinned in `infra/variables.tf`. GPU PCI BDFs for the Intel GPU worker are in `infra/main.tf`.

Keep `app-manifests` release pins (`cert_manager_release`, `argocd_release`, Gateway API / Envoy Gateway) matched to the Helm charts in `apps/` so CRDs are not older than the controllers.
