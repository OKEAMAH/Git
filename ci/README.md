# CI-in-OCaml

This directory contains an OCaml generator for the `.gitlab-ci.yml` in
the root of this repository.

This folder is structured like this:

 - `lib_gitlab_ci`: contains a partial, Octez-agnostic AST of [GitLab CI/CD YAML syntax](https://docs.gitlab.com/ee/ci/yaml/).
 - `bin`: contains a set of helpers for creating the Octez-specific
   `.gitlab-ci.yml` and the definition of this file in `main.ml`, as
   well as an executable for writing `.gitlab-ci.yml` based on that definition.

## Usage

To regenerate `.gitlab-ci.yml` (from the root of the repo):

    make -C ci all

To check that `.gitlab-ci.yml` is up-to-date (from the root of the repo):

    make -C ci check
