#!/bin/bash

# Get the directory where this script is located
SCRIPT_DIR=$(dirname "$0")

mongosh --host mongo -u user -p password --file "${SCRIPT_DIR}/queries.js"