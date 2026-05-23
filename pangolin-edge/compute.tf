data "oci_identity_availability_domains" "ads" {
  compartment_id = var.compartment_id
}

data "oci_core_images" "ubuntu" {
  compartment_id           = var.compartment_id
  operating_system         = "Canonical Ubuntu"
  operating_system_version = var.instance_os_version
  shape                    = var.instance_shape
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

resource "oci_core_instance" "pangolin" {
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[var.availability_domain_index].name
  compartment_id      = var.compartment_id
  display_name        = var.instance_display_name
  shape               = var.instance_shape

  dynamic "shape_config" {
    for_each = var.instance_shape == "VM.Standard.A1.Flex" ? [1] : []
    content {
      ocpus         = var.instance_ocpus
      memory_in_gbs = var.instance_memory_gbs
    }
  }

  source_details {
    source_type             = "image"
    source_id               = data.oci_core_images.ubuntu.images[0].id
    boot_volume_size_in_gbs = var.boot_volume_size_gbs
  }

  metadata = {
    ssh_authorized_keys = local.ssh_public_key_openssh
    user_data = base64encode(templatefile("${path.module}/templates/cloud-init.yaml.tmpl", {
      hostname = var.instance_display_name
    }))
  }

  create_vnic_details {
    subnet_id        = oci_core_subnet.pangolin_public.id
    assign_public_ip = false
  }
}

data "oci_core_vnic_attachments" "instance" {
  compartment_id = var.compartment_id
  instance_id    = oci_core_instance.pangolin.id
}

data "oci_core_private_ips" "primary" {
  vnic_id = local.primary_vnic_id

  depends_on = [oci_core_instance.pangolin]
}

resource "oci_core_public_ip" "pangolin" {
  compartment_id = var.compartment_id
  display_name   = "pangolin-edge"
  lifetime       = "RESERVED"

  private_ip_id = data.oci_core_private_ips.primary.private_ips[0].id

  depends_on = [oci_core_instance.pangolin]
}

# Pangolin install over SSH needs a reachable host after the reserved IP is attached.
resource "time_sleep" "wait_for_ssh" {
  count = var.install_pangolin_via_ssh ? 1 : 0

  create_duration = "90s"

  depends_on = [oci_core_public_ip.pangolin]
}
