#!/bin/sh

# We can't do linting on frozen protocol (protocols/proto_*/lib_protocol/*.ml) but we
# can still do it on the in-development protocol
# (protocols/proto_alpha/lib_protocol/*.ml). The `exclude` pattern below expresses
# this.
semgrep \
  --metrics=off \
  --error \
  -l ocaml \
  -c scripts/semgrep/ \
  --exclude "protocols/proto_[0-9]*/lib_protocol/*.ml*" \
  --exclude "src/lib_webassembly/*" \
  --exclude "src/bin_testnet_scenarios/*" \
  src/
