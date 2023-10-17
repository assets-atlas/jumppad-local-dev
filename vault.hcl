resource "container" "vault" {
    network {
        id         = resource.network.local.id
        aliases    = ["vault_ip_address"]
    }

    port {
        local  = 8200
        remote = 8200
        host   = 8200
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
  EOF

  # Mount a volume containing the config

  environment = {
    VAULT_ADDR = "http://localhost:8200"
    VAULT_TOKEN = variable.vault_token
  }

  depends_on = [
    "resource.container.vault"
  ]
}