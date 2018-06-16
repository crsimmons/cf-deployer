variable "domain" {}

resource "tls_private_key" "bbl_private_key" {
  algorithm = "RSA"
}

resource "tls_self_signed_cert" "bbl_cert" {
  key_algorithm   = "RSA"
  private_key_pem = "${tls_private_key.bbl_private_key.private_key_pem}"

  subject {
    common_name = "${var.domain}"
  }

  dns_names = [
    "*.${var.domain}",
    "*.system.${var.domain}",
    "*.uaa.system.${var.domain}",
    "*.doppler.system.${var.domain}",
    "*.login.system.${var.domain}",
    "*.apps.${var.domain}",
  ]

  validity_period_hours = 8760

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}

output "bbl_private_key" {
  value = "${tls_private_key.bbl_private_key.private_key_pem}"
}

output "bbl_cert" {
  value = "${tls_self_signed_cert.bbl_cert.cert_pem}"
}
