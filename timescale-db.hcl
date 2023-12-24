resource "container" "timescale_db" {
    network {
        id         = resource.network.local.id
        aliases    = ["db_ip_address"]
    }

    port {
        local  = 5432
        remote = 5432
        host   = 5432
    }


    image {
        name = "timescale/timescaledb:${variable.timescale_version}"
    }

    environment = {
        POSTGRES_PASSWORD = variable.timescale_password
        POSTGRES_USER     = variable.timescale_user
        POSTGRES_DB       = variable.timescale_db
    }

    health_check {

        timeout = "15s"

        exec {
            command = ["pg_isready"]
        }
    }
}

resource "remote_exec" "timescale_config" {

  target = resource.container.timescale_db

  network {
    id = resource.network.local.id
  }

  script = <<-EOF
#!/usr/bin/env bash

psql "host=localhost port=5432 dbname=${variable.timescale_db} user=${variable.timescale_user} password=${variable.timescale_password} sslmode=disable" \
  -c "CREATE USER vault WITH SUPERUSER PASSWORD 'password';"

psql "host=localhost port=5432 dbname=${variable.timescale_db} user=${variable.timescale_user} password=${variable.timescale_password} sslmode=disable" \
  -c 'CREATE TABLE users (
        id SERIAL PRIMARY KEY,
        email VARCHAR(255) UNIQUE NOT NULL,
        password VARCHAR(255) NOT NULL,
        first_name VARCHAR(255),
        middle_name VARCHAR(255),
        last_name VARCHAR(255),
        dob VARCHAR(255),
        key_name VARCHAR(255)
);'
  EOF

  depends_on = [
    "resource.container.timescale_db"
  ]
}
