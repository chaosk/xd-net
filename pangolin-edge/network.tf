resource "oci_core_vcn" "pangolin" {
  compartment_id = var.compartment_id
  cidr_blocks    = [var.vcn_cidr]
  display_name   = "pangolin-edge"
  dns_label      = "pangolin"
}

resource "oci_core_internet_gateway" "pangolin" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.pangolin.id
  display_name   = "pangolin-edge-igw"
  enabled        = true
}

resource "oci_core_route_table" "pangolin_public" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.pangolin.id
  display_name   = "pangolin-edge-public"

  route_rules {
    network_entity_id = oci_core_internet_gateway.pangolin.id
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
  }
}

resource "oci_core_security_list" "pangolin" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.pangolin.id
  display_name   = "pangolin-edge"

  ingress_security_rules {
    protocol = "6"
    source   = var.allow_ssh_cidr
    tcp_options {
      min = 22
      max = 22
    }
  }

  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"
    tcp_options {
      min = 80
      max = 80
    }
  }

  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"
    tcp_options {
      min = 443
      max = 443
    }
  }

  ingress_security_rules {
    protocol = "17"
    source   = "0.0.0.0/0"
    udp_options {
      min = 51820
      max = 51820
    }
  }

  ingress_security_rules {
    protocol = "17"
    source   = "0.0.0.0/0"
    udp_options {
      min = 21820
      max = 21820
    }
  }

  egress_security_rules {
    protocol    = "all"
    destination = "0.0.0.0/0"
  }
}

resource "oci_core_subnet" "pangolin_public" {
  compartment_id             = var.compartment_id
  vcn_id                     = oci_core_vcn.pangolin.id
  cidr_block                 = var.subnet_cidr
  display_name               = "pangolin-edge-public"
  dns_label                  = "public"
  route_table_id             = oci_core_route_table.pangolin_public.id
  security_list_ids          = [oci_core_security_list.pangolin.id]
  prohibit_public_ip_on_vnic = false
}
