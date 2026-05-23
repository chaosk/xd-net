# Talos + Proxmox + Terraform + ArgoCD (GitOps)

This bundle provisions a **Talos** Kubernetes cluster on **Proxmox VE**, installs **Cilium**, **Cert-Manager**, **ArgoCD** (with SOPS plugin), and **Synology CSI**.
ArgoCD uses an **ApplicationSet** to auto-load apps from a path in your Git repo. NAS creds are stored encrypted with **SOPS**.

## Layout
- `infra/` → Proxmox + Talos bootstrap
- `app-manifests/` → Cluster-wide CRDs (Gateway API*, cert-manager, Prometheus Operator CRDs, Argo CD via `kubernetes_manifest`; Envoy Gateway via `helm template | kubectl apply`) applied before `apps/`. \*Skip Gateway API if already installed (`install_gateway_api_crds = false`).
- `apps/`  → Platform via Terraform (Cilium, Cert-Manager, ArgoCD, Synology CSI)
- `pangolin-edge/` → Oracle Cloud edge for [Pangolin](https://pangolin.net) (VCN + VM + compose via Terraform); homelab connects via Newt (`pangolin-edge/README.md`)
- Git repo (external) → `secrets/` (SOPS encrypted), `apps/` (your apps like Plex)

## Quick start
1) **Provision cluster**
```bash
cd infra
terraform init
terraform apply
```

This writes these files automatically:
- `infra/_out/kubeconfig`
- `infra/_out/talosconfig`

2) **Configure your Git repo**
- Create Age key: `age-keygen -o ~/.config/sops/age/keys.txt` (copy public key)
- Create `secrets/synology-secret.yaml`, then encrypt:
```bash
sops --encrypt --age <YOUR_AGE_PUBLIC_KEY> --in-place secrets/synology-secret.yaml
git add secrets/synology-secret.yaml && git commit -m "synology creds" && git push
```
3) **Install CRDs** (once per cluster; requires kubeconfig from step 1)
```bash
cd ../app-manifests
terraform init
terraform apply
```

4) **Install platform**
```bash
cd ../apps

# Local, non-committed settings (ACME + Vercel DNS + Synology creds)
cp config.auto.tfvars.example config.auto.tfvars
$EDITOR config.auto.tfvars

terraform init
terraform apply
```
5) **Verify**
```bash
export KUBECONFIG=../infra/_out/kubeconfig
kubectl get nodes -o wide
kubectl -n kube-system get pods -l k8s-app=cilium
kubectl -n argocd get applicationsets,applications
kubectl get storageclass
```

## Git hooks

Commits must be [GPG-signed](https://git-scm.com/book/en/v2/Git-Tools-Signing-Your-Work). [pre-commit](https://pre-commit.com/) runs [require-signed-commits](https://github.com/pre-commit-garage/pre-commit-metadata-hooks) on `git push` and rejects any commit missing a `gpgsig` header.

One-time setup:

```bash
brew install pre-commit   # or: pip install pre-commit
pre-commit install
git config commit.gpgsign true
```

## Notes
- Update **GPU PCI BDFs** in `infra/main.tf`.
- Keep **`app-manifests`** release pins (`cert_manager_release`, `argocd_release`) at or above the versions implied by the Helm charts in `apps/` so CRDs are not older than the controllers.

## ArgoCD GitOps bootstrap
Terraform bootstraps ArgoCD to manage your external GitOps repo:
- `Application` **platform-secrets** → syncs `git_path_secrets` using the **SOPS** config management plugin
- `ApplicationSet` **apps** → auto-syncs `${git_path_apps}/*`


## Talos Linux Image Factory

Your image schematic ID is: 79d80db11c7f0e8bc14aaf940e3b5dbde519e5c9e746b5d0751dd0487a2d5167
```
customization:
    systemExtensions:
        officialExtensions:
            - siderolabs/amd-ucode
            - siderolabs/i915
            - siderolabs/iscsi-tools
            - siderolabs/qemu-guest-agent
```

Talos version + ISO URL/name are pinned in `infra/variables.tf`.
