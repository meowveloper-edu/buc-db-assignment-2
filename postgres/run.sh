#!/bin/bash

# Get the directory where this script is located
SCRIPT_DIR=$(dirname "$0")

# Run the psql command using a path relative to the script's directory
psql -h postgres -U user -d git_repo_db -f "${SCRIPT_DIR}/queries.sql"
