#!/bin/bash

psql84 -U postgres -c "CREATE DATABASE template_postgis WITH template = template1"
psql84 -U postgres -c "UPDATE pg_database SET datistemplate = TRUE WHERE datname = 'template_postgis'"
psql84 -U postgres template_postgis -c "CREATE LANGUAGE plpgsql"
