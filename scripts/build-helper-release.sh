#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "$script_dir/.." && pwd)"
source_bin="$repo_root/target/release/omatune-helper"
target_dir="$repo_root/bin"
target_bin="$target_dir/omatune-helper"
staging_bin="$target_bin.new"

cleanup() {
  rm -f "$staging_bin"
}

trap cleanup EXIT

cargo build --release --manifest-path "$repo_root/Cargo.toml" --bin omatune-helper
mkdir -p "$target_dir"
cp "$source_bin" "$staging_bin"
chmod +x "$staging_bin"
mv "$staging_bin" "$target_bin"

printf '%s\n' "staged helper: $target_bin"
