# Contribution guidelines

These are simple recommendations that should help to keep the codebase maintainable, ensure quick onboarding, and prevent the concentration of knowledge.

## Project structure

Please keep the modules within 500 LOC including comments and tests. If necessary — write tests in a separate `module_test.rs` file. Try to separate declarations and implementations to improve visibility. Encapsulate modules in a dedicated crate if it's a convenient abstraction and/or has heavy dependencies.

## File header

Always start your code/configuration files with a SPDX header containing author and license. For Rust crates/modules: use `//!` comments to describe what this crate/module is responsible for and any useful context that might help to understand the big picture.

## Documentation

If you introduce significant changes to the project (e.g. new sub-protocol or improvement) please consider outlining the design and rationale in the docs. Also make sure the documentation is up to date if any interfaces are altered. 

## Docstrings

All structures, enums, traits, and constants have to be documented (with `///` comments) as well as their fields/members (both public and private).

## Comments

Please add `//` comments for the code parts that might be ambiguous or not obvious. Remember that you are knowledge biased and whatever is clear to you (now) might not be clear to others (or future you).

## Tests

Any new feature or regression fix should be accompanied by a unit, integration (with mocked DSN), or E2E (with local cluster) test(s).

## Errors

Use a custom error enum type for every crate in the project. Cast errors with `thiserror` attributes or implement `From<E>` manually.

## Logging

Use `log::{trace, debug, info, warn, error}` for meaningful logging. Try to add as much context as possible to simplify troubleshooting.

## Linters

Use `cargo fmt` and `cargo clippy --fix`.