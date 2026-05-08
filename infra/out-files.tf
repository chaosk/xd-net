resource "local_file" "talosconfig" {
  filename        = local.talosconfig_path
  content         = data.talos_client_configuration.client.talos_config
  file_permission = "0600"
}

resource "local_file" "kubeconfig" {
  filename        = local.kubeconfig_path
  content         = talos_cluster_kubeconfig.kc.kubeconfig_raw
  file_permission = "0600"
}
