#!/bin/sh

#############################################################################
#                                                                           #
# Open Source License                                                       #
# Copyright (c) 2022 Nomadic Labs <contact@nomadic-labs.com>                #
#                                                                           #
# Permission is hereby granted, free of charge, to any person obtaining a   #
# copy of this software and associated documentation files (the "Software"),#
# to deal in the Software without restriction, including without limitation #
# the rights to use, copy, modify, merge, publish, distribute, sublicense,  #
# and/or sell copies of the Software, and to permit persons to whom the     #
# Software is furnished to do so, subject to the following conditions:      #
#                                                                           #
# The above copyright notice and this permission notice shall be included   #
# in all copies or substantial portions of the Software.                    #
#                                                                           #
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR#
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,  #
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL   #
# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER#
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING   #
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER       #
# DEALINGS IN THE SOFTWARE.                                                 #
#                                                                           #
#############################################################################

# This is a script to benchmark the Tezos gas parameters from a clone of
# https://gitlab.com/tezos/tezos.

# -x: echo run commands to stderr.
# -e: stop on first error.
set -x -e

TODAY=$(date +"%Y%m%d_%H%M")

dated_log() {
  date +"[%Y-%m-%d %T] $1."
}

dated_log "Starting benchmarks processes"

# Check that the previous process is over.
if [ -f "current_run_dir" ]; then
    dated_log "Can't start the benchmarks process for $TODAY: the previous process isn't over or has failed. cron_res, cron_res_errors and current_run_dir should contain clues to investigate the issue" >> anomalies
    exit 1
fi

# Clean _opam to have a fresh dependencies environment and fetch the latest
# commit.
cd /data/tezos-benchmarks/tezos
rm -rf _opam
echo "Pulling repository."
git pull
HEADCOMMIT=$(git describe --always --dirty --long)
echo -n "HEAD is $HEADCOMMIT"

SNOOP_RESULT_DIR="snoop_results/_snoop_${TODAY}_${HEADCOMMIT}"

# Create the result directory and register its name for tools that depend on it.
cd ..
echo "$SNOOP_RESULT_DIR" > current_run_dir
mkdir "$SNOOP_RESULT_DIR"

# Build dependencies.
# opam's solver can timeout sometimes, which does not mean that the remaining
# processes can't proceed, so we just pass the potential failures.
# However, this can lead to zcash_params not being properly installed; in this
# case, we copy the files directly.
cd tezos
dated_log "Compiling dependencies"
. "/home/mclaren/.cargo/env"
make BLST_PORTABLE=y build-dev-deps || true
if [ -d _opam/share/zcash-params ]; then echo "zcash params found"; else cp -r ../zcash-params _opam/share/; fi
eval $(opam env)

# Build Tezos
dated_log "Make"
make

# Run benchmarks.
dated_log "Running benchmarks"
time dune exec tezt/snoop/main.exe -- --verbose
dated_log "End of benchmarks run"

# Move results from tezos to their dedicated directory.
cd ..
mv tezos/_snoop/*_results "$SNOOP_RESULT_DIR"/
chmod +rx "$SNOOP_RESULT_DIR"/*_results

# Change the file containing the name of the result directory.
# This allows to use current_run_dir and last_run_dir as markers of the
# benchmarks being run (current_run_dir) or finished (last_run_dir).
PREVIOUS_SNOOP_RESULT_DIR="$(cat last_run_dir)"
mv current_run_dir last_run_dir

# Make the diff between the current run and the previous one.
paste -d "," "$PREVIOUS_SNOOP_RESULT_DIR"/inference_results/*.csv > "$CURRENT_SNOOP_RESULT_DIR"/previous_inference_results.csv
paste -d "," "$CURRENT_SNOOP_RESULT_DIR"/inference_results/*.csv > "$CURRENT_SNOOP_RESULT_DIR"/current_inference_results.csv
cd tezos/devtools/gas_parameter_diff
dune exec gas_parameter_diff -- "$CURRENT_SNOOP_RESULT_DIR"/previous_inference_results.csv "$CURRENT_SNOOP_RESULT_DIR"/current_inference_results.csv > "$CURRENT_SNOOP_RESULT_DIR"/inference_results_diff.csv

dated_log "End of benchmarks processes"
