#!/bin/bash
# MongoDB Docker Setup for Class Activity Manager

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
DOCKER_DIR="$PROJECT_DIR/docker"
ENV_FILE="$DOCKER_DIR/.env"
ENV_EXAMPLE="$DOCKER_DIR/.env.example"

echo "=== MongoDB Docker Setup ==="

# 1. Check Docker is installed and running
if ! command -v docker &> /dev/null; then
    echo "Error: Docker is not installed"
    exit 1
fi

if ! docker info &> /dev/null; then
    echo "Error: Docker daemon is not running"
    exit 1
fi

# 2. Check/create .env file from template
if [ ! -f "$ENV_FILE" ]; then
    if [ -f "$ENV_EXAMPLE" ]; then
        echo "Creating .env from .env.example..."
        cp "$ENV_EXAMPLE" "$ENV_FILE"
        echo ""
        echo "IMPORTANT: Edit docker/.env to set secure passwords before continuing!"
        echo "Then run this script again."
        echo ""
        exit 0
    else
        echo "Error: Neither .env nor .env.example found in docker/"
        exit 1
    fi
fi

# 3. Load environment variables
source "$ENV_FILE"

# 4. Start MongoDB container
echo "Starting MongoDB container..."
cd "$DOCKER_DIR"
docker compose up -d

# 5. Wait for MongoDB to be ready
echo "Waiting for MongoDB to be ready..."
sleep 5

# 6. Verify connection
echo "Verifying connection..."
docker exec cam_mongodb mongosh --eval "db.version()" --quiet

echo ""
echo "=== MongoDB Docker Setup Complete ==="
echo ""
echo "Connection strings (from your .env):"
echo "  App:     mongodb://${MONGO_APP_USER}:****@localhost:${MONGO_PORT}/${MONGO_APP_DATABASE}"
echo "  Admin:   mongodb://${MONGO_INITDB_ROOT_USERNAME}:****@localhost:${MONGO_PORT}/admin"
echo ""
echo "Mongo Express UI: http://localhost:${MONGO_EXPRESS_PORT}"
echo "  Login: ${MONGO_EXPRESS_USER} / (password from .env)"
echo ""
echo "Commands:"
echo "  Start:  ./scripts/mongo-start.sh"
echo "  Stop:   ./scripts/mongo-stop.sh"
echo "  Shell:  ./scripts/mongo-shell.sh"
echo "  Logs:   ./scripts/mongo-logs.sh"
