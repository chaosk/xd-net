locals {
  control_planes = [
    { id = 1, vmid = 901, name = "xd-c-1", fqdn = "xd-c-1.${var.domain_suffix}", macaddr = "bc:24:11:45:98:01", gpu = false },
    { id = 2, vmid = 902, name = "xd-c-2", fqdn = "xd-c-2.${var.domain_suffix}", macaddr = "bc:24:11:45:98:02", gpu = false },
    { id = 3, vmid = 903, name = "xd-c-3", fqdn = "xd-c-3.${var.domain_suffix}", macaddr = "bc:24:11:45:98:03", gpu = false },
  ]

  workers = [
    { id = 4, vmid = 904, name = "xd-w-1", fqdn = "xd-w-1.${var.domain_suffix}", macaddr = "bc:24:11:45:98:04", gpu = false },
    { id = 5, vmid = 905, name = "xd-w-2", fqdn = "xd-w-2.${var.domain_suffix}", macaddr = "bc:24:11:45:98:05", gpu = false },
    { id = 6, vmid = 906, name = "xd-w-3", fqdn = "xd-w-3.${var.domain_suffix}", macaddr = "bc:24:11:45:98:06", gpu = false },
  ]

  nodes     = concat(local.control_planes, local.workers)
  nodes_map = { for n in local.nodes : n.name => n }

  fqdns            = [for n in local.nodes : n.fqdn]
  first_control    = local.control_planes[0].fqdn
  cluster_endpoint = "${local.first_control}:6443"

  kubeconfig_path  = "${var.out_dir}/kubeconfig"
  talosconfig_path = "${var.out_dir}/talosconfig"
}
