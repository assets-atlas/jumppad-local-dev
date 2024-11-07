resource "docker_image" "vault" {
  name = "hashicorp/vault:${var.vault_version}"
}

resource "docker_container" "vault" {
  image = docker_image.vault.name
  name  = "vault"

  #  networks_advanced {
  #    name = docker_network.local_dev.name
  #  }

  capabilities {
    add = [
      "IPC_LOCK"
    ]
  }

  volumes {
    host_path      = "${path.cwd}/plugins"
    container_path = "/vault/plugins"
  }

  command = [
    "vault",
    "server",
    "-dev",
    "-dev-root-token-id=root",
    "-dev-plugin-dir=./vault/plugins"
  ]

  env = [
    "VAULT_ADDR=http://localhost:8200",
    "VAULT_DEV_ROOT_TOKEN_ID=${var.vault_dev_token}",
    "VAULT_LOG_LEVEL=debug"
  ]

  ports {
    internal = 8200
    external = 8200
    protocol = "tcp"
  }

  network_mode = "host"

  lifecycle {
    ignore_changes = [
      image,
      ports
    ]
  }
}

resource "terracurl_request" "vault_status" {

  method         = "GET"
  name           = "vault_status"
  response_codes = [200]
  url            = "http://localhost:8200/v1/sys/health"
  retry_interval = 10
  max_retry      = 6

  depends_on = [
    docker_container.vault
  ]
}

resource "vault_auth_backend" "email" {

  type = "email"

  depends_on = [
    terracurl_request.vault_status
  ]
}

resource "vault_identity_oidc_key" "oidc_key" {
  name               = var.oidc_key_name
  rotation_period    = 3600
  algorithm          = "RS256"
  allowed_client_ids = ["*"]
  verification_ttl   = 7200

  depends_on = [
    terracurl_request.vault_status
  ]
}

resource "vault_identity_oidc" "oidc" {

  issuer = var.vault_address

  depends_on = [
    terracurl_request.vault_status
  ]

  lifecycle {
    ignore_changes = [
      id
    ]
  }
}

resource "vault_identity_oidc_role" "role" {
  key      = vault_identity_oidc_key.oidc_key.name
  name     = var.oidc_role_name
  template = <<EOF
{
 "email": {{identity.entity.metadata.email}},
 "username": {{identity.entity.name}}
}
EOF
  ttl      = 3600

  depends_on = [
    terracurl_request.vault_status
  ]
}

resource "vault_policy" "jwt" {
  name   = "jwt"
  policy = <<EOF
path "/identity/oidc/token/${var.oidc_role_name}" {
   capabilities = ["read"]
}
EOF
  depends_on = [
    terracurl_request.vault_status
  ]
}

resource "vault_mount" "transit" {
  path = "transit"
  type = "transit"

  depends_on = [
    terracurl_request.vault_status
  ]
}

resource "vault_transit_secret_backend_key" "api" {
  backend               = vault_mount.transit.path
  name                  = "api"
  derived               = true
  convergent_encryption = true
  deletion_allowed      = true
}

#resource "vault_generic_endpoint" "test_users" {
#  for_each = var.test_users
#  data_json = <<EOF
#{
#  "username": "${each.value["email"]}"
#  "password": "${each.value["password"]}"
#}
#EOF
#  path      = ""
#}

output "mount_accessor" {
  value = vault_auth_backend.email.accessor
}

output "transit_key_name" {
  value = vault_transit_secret_backend_key.api.name
}
