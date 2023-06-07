#!/bin/sh

set -eu

script_dir="$(cd "$(dirname "$0")" && echo "$(pwd -P)/")"

OPAM_WRAPPER=${OPAM_WRAPPER:-${script_dir}profile-opam.sh}

cat >> "$OPAM_SWITCH_PREFIX"/.opam-switch/switch-config << EOT
wrap-build-commands:
  ["$OPAM_WRAPPER" "build"] {os = "linux" | os = "macos"}
wrap-install-commands:
  ["$OPAM_WRAPPER" "install"] {os = "linux" | os = "macos"}
wrap-remove-commands:
  ["$OPAM_WRAPPER" "remove"] {os = "linux" | os = "macos"}
EOT
