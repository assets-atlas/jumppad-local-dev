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
  -c '
CREATE TABLE users (
        id SERIAL PRIMARY KEY,
        email VARCHAR(255) UNIQUE NOT NULL,
        mobile VARCHAR(255) UNIQUE NOT NULL,
        entity_id VARCHAR(255) NOT NULL,
        alias_id VARCHAR(255) NOT NULL,
        first_name VARCHAR(255),
        middle_name VARCHAR(255),
        last_name VARCHAR(255),
        dob VARCHAR(255)
);

CREATE TABLE coinbase (
    id SERIAL PRIMARY KEY,
    user_id INTEGER UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    refresh_token VARCHAR(255),
    access_token VARCHAR(255),
    token_expiry TIMESTAMP
);

CREATE TABLE insurance (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(255),
    insurer VARCHAR(255),
    insurance_type VARCHAR(255),
    policy_number VARCHAR(255),
    insured_amount NUMERIC(15, 2),
    start_date DATE,
    end_date DATE,
    policy_documents TEXT,
    CONSTRAINT unique_insurer_policy_number UNIQUE (insurer, policy_number)
);

CREATE TABLE properties (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    paon VARCHAR(100),                         -- Primary Addressable Object Name (e.g., "9")
    street VARCHAR(100),
    town VARCHAR(100),
    district VARCHAR(100),
    county VARCHAR(100),
    postcode VARCHAR(10),
    description VARCHAR(255),                 -- Full address description
    type VARCHAR(50),                         -- Property type (e.g., Detached)
    tenure VARCHAR(50),                       -- Freehold/Leasehold
    age VARCHAR(50),                          -- Construction age range
    built_form VARCHAR(50),                   -- Built form (e.g., Detached)
    floor_area FLOAT,                         -- Total floor area in square meters
    habitable_rooms INT,                      -- Number of habitable rooms
    heated_rooms INT,                         -- Number of heated rooms
    current_energy_rating CHAR(1),            -- Current EPC energy rating
    potential_energy_rating CHAR(1),          -- Potential EPC energy rating
    pid VARCHAR(100),                         -- Property identifier
    latitude FLOAT,                           -- GPS latitude
    longitude FLOAT,                          -- GPS longitude
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE property_values (
    id SERIAL PRIMARY KEY,
    property_id INTEGER NOT NULL,
    date DATE NOT NULL,                       -- Date of value estimation
    estimated_value FLOAT NOT NULL,           -- Estimated property value
    price_per_sqm FLOAT,                      -- Estimated price per square meter
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (property_id) REFERENCES properties(id) ON DELETE CASCADE
);

CREATE TABLE epc_costs_history (
    id SERIAL PRIMARY KEY,
    property_id INTEGER NOT NULL,
    date DATE NOT NULL,                       -- Date of cost estimation
    cost_type VARCHAR(50) NOT NULL,           -- Cost type: Lighting, Heating, Water, etc.
    current_cost FLOAT,                       -- Current estimated cost
    potential_cost FLOAT,                     -- Potential cost after improvements
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (property_id) REFERENCES properties(id) ON DELETE CASCADE
);

CREATE TABLE council_tax (
    id SERIAL PRIMARY KEY,
    property_id INTEGER NOT NULL,
    band VARCHAR(10) NOT NULL,                -- Council tax band (e.g., A, B, C, F)
    annual_cost FLOAT NOT NULL,               -- Annual council tax cost
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (property_id) REFERENCES properties(id) ON DELETE CASCADE
);

CREATE TABLE coinbase_portfolio (
      id SERIAL PRIMARY KEY,
      user_id INT REFERENCES users(id) ON DELETE CASCADE,
      asset_id VARCHAR(255),         -- Unique identifier for each asset or account
      balance DECIMAL(18, 8),        -- Balance of the asset
      asset_name VARCHAR(255),       -- Name of the asset, e.g., "Bitcoin"
      asset_symbol VARCHAR(10),      -- Symbol of the asset, e.g., "BTC"
      timestamp TIMESTAMP DEFAULT NOW(),  -- Timestamp for the snapshot
      CONSTRAINT unique_snapshot UNIQUE (user_id, asset_id, timestamp)
  );

CREATE TABLE binance (
    id SERIAL PRIMARY KEY,
    user_id INTEGER UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    refresh_token VARCHAR(255),
    access_token VARCHAR(255),
    token_expiry TIMESTAMP,
    api_key VARCHAR(255),
    secret_key VARCHAR(255)
);

CREATE TABLE binance_portfolio (
    id SERIAL PRIMARY KEY,                 -- Unique identifier for each portfolio record
    user_id INT NOT NULL,                  -- Foreign key linking to the users table
    recorded_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, -- Timestamp of the record
    account_type VARCHAR(50) NOT NULL,     -- Type of account (e.g., SPOT)
    update_time BIGINT NOT NULL,           -- Update time from Binance API
    asset VARCHAR(50) NOT NULL,            -- Asset name (e.g., BTC, ETH)
    free_amount NUMERIC(20, 8) NOT NULL,   -- Free balance of the asset
    locked_amount NUMERIC(20, 8) NOT NULL, -- Locked balance of the asset
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
'
EOF

  }
}