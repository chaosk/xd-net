# Minimal Argo CD CMP sidecar base: Alpine + static sops on PATH.
# argocd-cmp-server is mounted at runtime from the repo-server volume.
FROM docker.io/library/alpine:3.22

ARG SOPS_VERSION=3.13.3
ARG TARGETARCH

RUN wget -qO /usr/local/bin/sops \
      "https://github.com/getsops/sops/releases/download/v${SOPS_VERSION}/sops-v${SOPS_VERSION}.linux.${TARGETARCH}" \
  && chmod +x /usr/local/bin/sops \
  && sops --version

# Matches Argo CD CMP sidecar securityContext runAsUser.
USER 999
