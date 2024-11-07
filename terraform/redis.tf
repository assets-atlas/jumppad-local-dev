resource "docker_image" "redis" {
  name = "redis:${var.redis_version}"
}

resource "docker_container" "redis" {

  image = docker_image.redis.name
  name  = var.redis_container_name

  network_mode = "host"

  ports {
    internal = 6379
    external = 6379
    protocol = "tcp"
  }

  env = [
    "REDIS_ARGS=--requirepass password --user username on >password ~* allcommands --user default off nopass nocommands",
  ]
}

