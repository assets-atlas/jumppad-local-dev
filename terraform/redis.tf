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

  volumes {
    host_path      = "${path.cwd}/redis.conf"
    container_path = "/usr/local/etc/redis/redis.conf"
  }

  command = ["redis-server", "/usr/local/etc/redis/redis.conf"]

  lifecycle {
    ignore_changes = [
      image,
      ports
    ]
  }
}