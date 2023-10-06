#!/bin/sh

set -eu

# misc linting
find . ! -path "./_opam/*" -name "*.opam" -exec opam lint {} +;

make check-linting

# Check that new ml(i) files have a MIT-SPDX license header.
git diff-tree --no-commit-id --name-only -r --diff-filter=A \
    "${CI_MERGE_REQUEST_DIFF_BASE_SHA:-master}" HEAD |
    grep '\.ml\(i\|\)$' |
    xargs ocaml scripts/check_license/main.ml --verbose --mit-spdx
echo "OCaml file license headers OK!"

# python checks
make check-python-linting
make check-python-typecheck

# Ensure that all unit tests are restricted to their opam package
make lint-tests-pkg

# FIXME: https://gitlab.com/tezos/tezos/-/issues/2971
# The new version of odoc (2.1.0) is stricter than the old version (1.5.3),
# we temporarily deactivate the odoc checks.
## Ensure there are no mli docstring syntax errors in alpha protocol
#- ODOC_WARN_ERROR=true dune build @src/proto_alpha/lib_protocol/doc
# check that the hack-module patch applies cleanly
git apply devtools/protocol-print/add-hack-module.patch

# check that yes-wallet builds correctly
dune build devtools/yes_wallet/yes_wallet.exe

# check that the patch-yes_node.sh applies correctly
scripts/patch-yes_node.sh --dry-run
