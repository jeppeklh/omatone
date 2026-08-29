#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "$script_dir/.." && pwd)"

packaged_helper="$repo_root/bin/omatune-helper"
debug_helper="$repo_root/target/debug/omatune-helper"
release_helper="$repo_root/target/release/omatune-helper"

if [[ -n "${OMATUNE_HELPER_BIN:-}" && -x "${OMATUNE_HELPER_BIN}" ]]; then
  exec "${OMATUNE_HELPER_BIN}" "$@"
fi

if [[ -x "$packaged_helper" ]]; then
  exec "$packaged_helper" "$@"
fi

if [[ -x "$debug_helper" ]]; then
  exec "$debug_helper" "$@"
fi

if [[ -x "$release_helper" ]]; then
  exec "$release_helper" "$@"
fi

if command -v cargo >/dev/null 2>&1; then
  # Development bootstrap when no packaged helper is present.
  exec cargo run --quiet --manifest-path "$repo_root/Cargo.toml" --bin omatune-helper -- "$@"
fi

printf '%s\n' 'omatune-helper launcher: no packaged or built helper found and cargo is unavailable' >&2
exit 1
