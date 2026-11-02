#!/bin/bash

set -euo pipefail

# Set up misc dir
target_dir="/misc"
sudo chown "$(id -un):$(id -gn)" "$target_dir"

target_sub_dirs=(
  "claude"
  "gh"
)

for dir in "${target_sub_dirs[@]}"; do
  echo "Creating sub directory: ${target_dir}/${dir}"
  mkdir -p "${target_dir}/${dir}"
done
