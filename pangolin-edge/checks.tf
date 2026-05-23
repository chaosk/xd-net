check "letsencrypt_email_real" {
  assert {
    condition     = var.letsencrypt_email != "" && !can(regex("(?i)example\\.com$", var.letsencrypt_email))
    error_message = "Set letsencrypt_email to a real address (not you@example.com). Used by Traefik ACME and Pangolin admin."
  }
}

check "vercel_dns_token" {
  assert {
    condition     = !var.manage_vercel_dns || (var.vercel_api_token != null && var.vercel_api_token != "")
    error_message = "vercel_api_token is required when manage_vercel_dns is true."
  }
}

check "ssh_key_pair" {
  assert {
    condition = var.ssh_public_key_path == null || var.ssh_private_key_path != null
    error_message = "ssh_private_key_path is required when ssh_public_key_path is set."
  }
}

check "ssh_key_pair_public" {
  assert {
    condition = var.ssh_private_key_path == null || var.ssh_public_key_path != null
    error_message = "ssh_public_key_path is required when ssh_private_key_path is set."
  }
}
