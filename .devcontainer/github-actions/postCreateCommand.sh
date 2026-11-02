#!/bin/bash

set -euo pipefail

# Set up misc dir
target_dir="/misc"
sudo chown "$(id -un):$(id -gn)" "$target_dir"

target_sub_dirs=(
  "claude"
  "gh"
  "herdr"
  "state"
)

for dir in "${target_sub_dirs[@]}"; do
  echo "Creating sub directory: ${target_dir}/${dir}"
  mkdir -p "${target_dir}/${dir}"
done

# Activate mise in interactive shells
# shellcheck disable=SC2016 # Written literally to .bashrc
activate_line='eval "$(mise activate bash)"'
if ! grep -qxF "$activate_line" "${HOME}/.bashrc"; then
  echo "$activate_line" >>"${HOME}/.bashrc"
fi

# Install tools defined in mise.toml
cd "$(dirname "$0")/../.."
mise trust
mise install
