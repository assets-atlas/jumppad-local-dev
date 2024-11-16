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
    api_token VARCHAR(255)
);


CREATE TABLE truelayer_tokens (
    user_id INT PRIMARY KEY,
    access_token VARCHAR NOT NULL,
    refresh_token VARCHAR NOT NULL,
    token_expiry TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE TABLE truelayer_bank_accounts (
    account_id VARCHAR PRIMARY KEY,
    user_id INT,
    account_type VARCHAR,
    account_name VARCHAR,
    currency VARCHAR(3),
    balance DECIMAL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE TABLE truelayer_transactions (
    transaction_id VARCHAR PRIMARY KEY,
    account_id VARCHAR,
    user_id INT,
    amount DECIMAL,
    currency VARCHAR(3),
    description VARCHAR,
    transaction_date TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (account_id) REFERENCES truelayer_bank_accounts(account_id),
    FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE TABLE truelayer_credit_commitments (
    commitment_id VARCHAR PRIMARY KEY,
    user_id INT,
    commitment_type VARCHAR,
    provider VARCHAR,
    balance DECIMAL,
    interest_rate DECIMAL,
    monthly_payment DECIMAL,
    due_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id)
);

-- Create a trigger function to update the updated_at column
CREATE OR REPLACE FUNCTION update_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Add the trigger to each table
CREATE TRIGGER set_timestamp
BEFORE UPDATE ON truelayer_tokens
FOR EACH ROW
EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER set_timestamp
BEFORE UPDATE ON truelayer_bank_accounts
FOR EACH ROW
EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER set_timestamp
BEFORE UPDATE ON truelayer_transactions
FOR EACH ROW
EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER set_timestamp
BEFORE UPDATE ON truelayer_credit_commitments
FOR EACH ROW
EXECUTE FUNCTION update_timestamp();'

EOF
  }
}