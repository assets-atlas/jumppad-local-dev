variable "vault_token" {
  default = "root"
}

variable "version" {
  default = "1.15.0"
}

variable "timescale_version" {
    default = "2.12.1-pg13"
}

variable "timescale_password" {
    default = "password"
}

variable "timescale_user" {
    default = "user"
}

variable "timescale_db" {
    default = "assets_atlas"
}