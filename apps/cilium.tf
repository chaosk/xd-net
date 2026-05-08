resource "cilium" "cilium" {
  set = [
    "ipam.mode=kubernetes",
    "kubeProxyReplacement=true",
    "k8sServiceHost=localhost",
    "k8sServicePort=7445",
    "devices=ens+",
    "securityContext.capabilities.ciliumAgent={CHOWN,KILL,NET_ADMIN,NET_RAW,IPC_LOCK,SYS_ADMIN,SYS_RESOURCE,DAC_OVERRIDE,FOWNER,SETGID,SETUID}",
    "securityContext.capabilities.cleanCiliumState={NET_ADMIN,SYS_ADMIN,SYS_RESOURCE}",
    "cgroup.autoMount.enabled=false",
    "cgroup.hostRoot=/sys/fs/cgroup",
    "gatewayAPI.enabled=true",
    "gatewayAPI.enableAlpn=true",
    "gatewayAPI.enableAppProtocol=true"
  ]

  version = "1.18.2"
}

resource "cilium_hubble" "hubble" {
  ui    = true
  relay = true

  depends_on = [cilium.cilium]
}
