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

# Install gh extensions, which mise does not manage. Keep the gh actions-lock
# version in sync with .github/workflows/run_github_actions_lint.yaml
# gh needs authentication to install extensions; on first create, run
# `gh auth login` and then this command manually
if gh auth status >/dev/null 2>&1; then
  gh extension install github/gh-actions-lock --pin v0.4.1
else
  echo "Skip: gh is not authenticated; run 'gh auth login' and then" \
    "'gh extension install github/gh-actions-lock --pin v0.4.1'"
fi

# Install Git hooks defined in lefthook.yml
lefthook install
