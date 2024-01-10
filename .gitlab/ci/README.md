# CI guideline

This document describes the operating principles of the source code
around the CI.

# Job file names

 - If a job file contains the definition of a single GitLab CI job,
   then the file should have the same name as the job.
 - If a job file defines several jobs sharing a common descriptive
   prefix, then the file should be named after that prefix.
 - If there is no such common prefix, or if it is not descriptive, an
   arbitrary by descriptive name can be used.

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
