resource "docker_image" "timescale_db" {

  name = "timescale/timescaledb:${var.timescale_version}"

}

resource "docker_container" "timescale_db" {

  image = docker_image.timescale_db.name
  name  = var.timescale_db_container_name

#  networks_advanced {
#    name = docker_network.local_dev.name
#  }

  network_mode = "host"

  env = [
    "POSTGRES_PASSWORD=${var.timescale_password}",
    "POSTGRES_USER=${var.timescale_user}",
    "POSTGRES_DB=${var.timescale_db}"
  ]

  ports {
    internal = 5432
    external = 5432
    protocol = "tcp"
  }

  provisioner "local-exec" {
    command = <<EOF
until docker exec ${var.timescale_db_container_name} pg_isready ; do sleep 5 ; done
EOF
  }

  lifecycle {
    ignore_changes = [
      image,
      ports
    ]
  }
}

resource "null_resource" "run_script" {
  depends_on = [docker_container.timescale_db]

  provisioner "local-exec" {
    command = <<EOF
docker exec ${var.timescale_db_container_name} psql "host=localhost port=5432 dbname=${var.timescale_db} user=${var.timescale_user} password=${var.timescale_password} sslmode=disable" \
  -c "CREATE USER vault WITH SUPERUSER PASSWORD 'password';"

docker exec ${var.timescale_db_container_name} psql "host=localhost port=5432 dbname=${var.timescale_db} user=${var.timescale_user} password=${var.timescale_password} sslmode=disable" \
  -c 'CREATE TABLE users (
        id SERIAL PRIMARY KEY,
        email VARCHAR(255) UNIQUE NOT NULL,
        mobile VARCHAR(255) UNIQUE NOT NULL,
        entity_id VARCHAR(255) NOT NULL,
        alias_id VARCHAR(255) NOT NULL,
        first_name VARCHAR(255),
        middle_name VARCHAR(255),
        last_name VARCHAR(255),
        dob VARCHAR(255)
);'
docker exec ${var.timescale_db_container_name} psql "host=localhost port=5432 dbname=${var.timescale_db} user=${var.timescale_user} password=${var.timescale_password} sslmode=disable" \
  -c 'CREATE TABLE coinbase (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    refresh_token VARCHAR(255),
    access_token VARCHAR(255),
    token_expiry TIMESTAMP
);'

EOF
  }
}