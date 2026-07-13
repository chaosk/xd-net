locals {
  cilium_helm_sets = [
    "ipam.mode=kubernetes",
    "kubeProxyReplacement=true",
    "k8sServiceHost=localhost",
    "k8sServicePort=7445",
    # Primary compute VLAN only (192.168.4.0/24). Do not use ens+ — workers also
    # have ens19 as the Multus macvlan parent (IoT 192.168.2.0/24); attaching Cilium
    # there makes it BPF-filter IoT broadcast/multicast and burns CPU.
    "devices=ens18",
    "securityContext.capabilities.ciliumAgent={CHOWN,KILL,NET_ADMIN,NET_RAW,IPC_LOCK,SYS_ADMIN,SYS_RESOURCE,DAC_OVERRIDE,FOWNER,SETGID,SETUID}",
    "securityContext.capabilities.cleanCiliumState={NET_ADMIN,SYS_ADMIN,SYS_RESOURCE}",
    "cgroup.autoMount.enabled=false",
    "cgroup.hostRoot=/sys/fs/cgroup",
    # L7 ingress uses Envoy Gateway (apps/envoy-gateway.tf), not Cilium's bundled envoy.
    # No CiliumNetworkPolicy L7 rules — drop cilium-envoy DaemonSet (enable-l7-proxy).
    "gatewayAPI.enabled=false",
    "l7Proxy=false",
    "envoy.enabled=false",
    # Required for CiliumLoadBalancerIPPool + CiliumL2AnnouncementPolicy to take effect:
    # LB IPAM is default (defaultLBServiceIPAM=lbipam); L2 ARP/NDP for those IPs is opt-in.
    "l2announcements.enabled=true",
    # Allow Multus alongside Cilium when multus_enabled (see multus.tf).
    var.multus_enabled ? "cni.exclusive=false" : "cni.exclusive=true",
    # Prometheus metrics — https://docs.cilium.io/en/stable/observability/metrics/
    "prometheus.enabled=true",
    "operator.prometheus.enabled=true",
    "prometheus.metricsService=true",
    "operator.prometheus.metricsService=true",
    # flow/port-distribution/tcp/icmp aggregate every Hubble event into high-cardinality
    # Prometheus series and burn CPU; dns+drop cover homelab debugging (drops also in cilium_*).
    "hubble.metrics.enabled={dns,drop}",
    "hubble.metrics.enableOpenMetrics=true",
    # cilium-agent — cap RAM/CPU so OOM/thrash kills the pod, not the node (was BestEffort).
    "resources.requests.memory=${var.cilium_agent_memory_request}",
    "resources.limits.memory=${var.cilium_agent_memory_limit}",
    "resources.requests.cpu=${var.cilium_agent_cpu_request}",
    "resources.limits.cpu=${var.cilium_agent_cpu_limit}",
    "initResources.requests.memory=${var.cilium_init_memory_request}",
    "initResources.limits.memory=${var.cilium_init_memory_limit}",
    # cilium-operator
    "operator.resources.requests.memory=${var.cilium_operator_memory_request}",
    "operator.resources.limits.memory=${var.cilium_operator_memory_limit}",
    "operator.resources.requests.cpu=${var.cilium_operator_cpu_request}",
    "operator.resources.limits.cpu=${var.cilium_operator_cpu_limit}",
    # hubble-relay
    "hubble.relay.resources.requests.memory=${var.cilium_hubble_relay_memory_request}",
    "hubble.relay.resources.limits.memory=${var.cilium_hubble_relay_memory_limit}",
    # hubble-ui
    "hubble.ui.backend.resources.requests.memory=${var.cilium_hubble_ui_backend_memory_request}",
    "hubble.ui.backend.resources.limits.memory=${var.cilium_hubble_ui_backend_memory_limit}",
    "hubble.ui.frontend.resources.requests.memory=${var.cilium_hubble_ui_frontend_memory_request}",
    "hubble.ui.frontend.resources.limits.memory=${var.cilium_hubble_ui_frontend_memory_limit}",
  ]
}

resource "cilium" "cilium" {
  set     = local.cilium_helm_sets
  version = var.cilium_version
}

resource "cilium_hubble" "hubble" {
  ui    = true
  relay = true

  depends_on = [cilium.cilium]
}
