#!/bin/sh

set -ex

./scripts/remove-old-protocols.sh .trash
make all SHELL=$(pwd)/scripts/timing.sh
./scripts/restore-old-protocols.sh .trash
make -C docs -j all SHELL=$(pwd)/scripts/timing.sh

cat /tmp/make_log
