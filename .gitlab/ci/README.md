# CI guideline

This document describes the operating principles of the source code
around the CI.

# Implementation of job `script`s

These rules also apply to `before_script` and `after_script`.

## Inline scripts

I.e., having the `script` in the YAML definition of the job. Inline
scripts MUST only be used for small job definitions (less than 5
lines) that do not use any control flow.

## Calling out to a script

`script` definitions longer than 5 lines of code OR that use
control-flow MUST be placed in a separate shell script.

## Organizing `before_script:` sections

A job's `before_script:` section should be used to:

 - take ownership of checkout with `scripts/ci/take_ownership.sh`
 - source `scripts/version.sh`
 - load opam environment with `eval $(opam env)`
 - load Python venv with `. $HOME/.venv/bin/activate`
 - install NPM dependencies with `. ./scripts/install_build_deps.js.sh`

For consistency, these actions (or a subset thereof) should be taken
in the order listed above.
