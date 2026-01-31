#!/bin/bash
# Start MongoDB Docker containers

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/../docker"

if [ ! -f .env ]; then
    echo "Error: docker/.env not found. Run ./scripts/setup-mongodb.sh first."
    exit 1
fi

docker compose up -d
source .env 2>/dev/null
echo "MongoDB started. UI at http://localhost:${MONGO_EXPRESS_PORT:-8081}"
