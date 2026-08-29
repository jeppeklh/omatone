#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "$script_dir/.." && pwd)"
source_bin="$repo_root/target/release/omatune-helper"
target_dir="$repo_root/bin"
target_bin="$target_dir/omatune-helper"

cargo build --release --manifest-path "$repo_root/Cargo.toml" --bin omatune-helper
mkdir -p "$target_dir"
cp "$source_bin" "$target_bin"
chmod +x "$target_bin"

printf '%s\n' "staged helper: $target_bin"
