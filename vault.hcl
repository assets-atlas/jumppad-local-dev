resource "container" "vault" {
    network {
        id         = resource.network.local.id
        aliases    = ["vault.container.jumppad.dev"]
    }

    port {
        local  = 8200
        remote = 8200
        host   = 8200
        open_in_browser = true
    }


    image {
        name = "hashicorp/vault:${variable.version}"
    }

    environment = {
        VAULT_DEV_ROOT_TOKEN_ID = variable.vault_token
        VAULT_ADDR              = "http://localhost:8200"
    }

    health_check {

        timeout = "15s"

        exec {
            command = ["vault", "status"]
        }
    }


}

resource "remote_exec" "vault_config" {

  target = resource.container.vault

  network {
    id = resource.network.local.id
  }

  script = <<-EOF
#!/bin/sh
vault secrets enable transit

vault write -f transit/keys/test derived=true convergent_encryption=true

vault kv put secret/jwt key=secret-key

vault kv put secret/database user=user password=password

vault secrets enable database

vault write database/config/timescale \
    plugin_name="postgresql-database-plugin" \
    connection_url="postgresql://{{username}}:{{password}}@${resource.container.timescale_db.container_name}:5432/${variable.timescale_db}" \
    allowed_roles="api" \
    username="vault" \
    password="password"

vault write database/roles/api \
    db_name="timescale" \
    creation_statements="CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; \
        GRANT SELECT ON ALL TABLES IN SCHEMA public TO \"{{name}}\";" \
    revocation_statements="REVOKE ALL PRIVILEGES ON ALL TABLES IN SCHEMA public FROM \"{{name}}\"; DROP OWNED BY \"{{name}}\"; DROP ROLE \"{{name}}\";"
    default_ttl="1h" \
    max_ttl="24h"

vault auth enable userpass

  EOF

  # Mount a volume containing the config

  environment = {
    VAULT_ADDR  = "http://localhost:8200"
    VAULT_TOKEN = variable.vault_token
  }

  depends_on = [
    "resource.container.vault",
    "resource.remote_exec.timescale_config"
  ]
}