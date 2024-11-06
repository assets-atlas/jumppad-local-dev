variable "vault_version" {
  description = "The version of Vault to deploy"
  type        = string
  default     = "1.17"
}

variable "vault_dev_token" {
  description = "Root token for Vault in dev mode"
  type        = string
  default     = "root"
}

variable "oidc_key_name" {
  description = "Name of OIDC key used to sign JWTs"
  type        = string
  default     = "my-key"
}

variable "oidc_role_name" {
  description = "Name of OIDC role to generate JWTs"
  type        = string
  default     = "jwt"
}

variable "vault_address" {
  description = "Address of Vault server"
  type        = string
  default     = "http://localhost:8200"
}

variable "timescale_version" {
  description = "Version of Timescale DB to run"
  type        = string
  default     = "2.12.1-pg13"
}

variable "timescale_password" {
  description = "The default password for the database"
  type        = string
  default     = "password"
}

variable "timescale_user" {
  description = "The default user for the database"
  type        = string
  default     = "user"
}

variable "timescale_db" {
  description = "The name of the database"
  type        = string
  default     = "assetsatlas"
}

variable "timescale_db_container_name" {
  description = "Name of docker container for timescaledb"
  type        = string
  default     = "timescale_db"
}

variable "test_users" {
  type = list(map(string))
  default = [
    {
      email    = "testuser1@assetsatlas.com"
      password = "password"
    },
    {
      email    = "testuser2@assetsatlas.com"
      password = "password"
    },
    {
      email    = "testuser3@assetsatlas.com"
      password = "password"
    },
    {
      email    = "testuser4@assetsatlas.com"
      password = "password"
    },
    {
      email    = "testuser5@assetsatlas.com"
      password = "password"
    }
  ]
}