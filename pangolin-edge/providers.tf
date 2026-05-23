provider "oci" {
  region = var.oci_region
  # Auth via ~/.oci/config — see README.md. Set oci_config_profile if not using DEFAULT.
  config_file_profile = var.oci_config_profile
}

provider "vercel" {
  # Required when manage_vercel_dns = true (see checks.tf). team_id is set per vercel_dns_record.
  api_token = coalesce(var.vercel_api_token, "unset")
}
