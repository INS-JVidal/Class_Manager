#!/bin/bash
# Open MongoDB shell in container

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/../docker/.env"

if [ ! -f "$ENV_FILE" ]; then
    echo "Error: docker/.env not found. Run ./scripts/setup-mongodb.sh first."
    exit 1
fi

source "$ENV_FILE"
docker exec -it cam_mongodb mongosh -u "$MONGO_APP_USER" -p "$MONGO_APP_PASSWORD" "$MONGO_APP_DATABASE"
