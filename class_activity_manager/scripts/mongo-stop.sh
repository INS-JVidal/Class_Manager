#!/bin/bash
# Stop MongoDB Docker containers

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/../docker"

docker compose down
echo "MongoDB stopped."
