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
        dob VARCHAR(255)
);'
