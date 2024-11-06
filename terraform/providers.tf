terraform {
  required_providers {

    docker = {
      source  = "kreuzwerker/docker"
      version = "3.0.2"
    }

    terracurl = {
      source  = "devops-rob/terracurl"
      version = "1.2.1"
    }

    postgresql = {
      source  = "cyrilgdn/postgresql"
      version = "1.22.0"
    }
  }
}

provider "docker" {
  host = "unix:///var/run/docker.sock"
}

provider "vault" {
  address = var.vault_address
  token   = var.vault_dev_token

  max_retries = 10
}

provider "postgresql" {
  host            = "localhost"
  port            = 5432
  database        = "assetsatlas"
  username        = "user"
  password        = "password"
  sslmode         = "disable"
  connect_timeout = 15
}