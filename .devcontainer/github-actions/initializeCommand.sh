#!/bin/bash

set -euo pipefail

# Runs on the host before the container is created.
# Generate .devcontainer/.env from the host user if it does not exist.
env_file="$(cd "$(dirname "$0")/.." && pwd)/.env"

if [[ -f "$env_file" ]]; then
  echo "Skip: ${env_file} already exists"
  exit 0
fi

echo "Creating ${env_file}"
cat > "$env_file" <<EOT
CONTAINER_USER=$(id -un)
CONTAINER_UID=$(id -u)
CONTAINER_GID=$(id -g)
EOT
