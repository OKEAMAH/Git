# Changelog

## Version 3.1.0

### Breaking Changes

- On OCaml 4.12.1 or earlier, the new `?seed` argument can break calls to
  `Test.register` which are written using the form
  `Test.register ~__FILE__ ~title ~tags @@ fun () -> ...`.
  To fix this, either upgrade to OCaml 4.13.0 or later, add `?seed: None`,
  or replace `@@` with parentheses.

- Internal type `Test.SCHEDULER.response` changed.
  This change is very unlikely to impact you unless you wrote your own backend.

- `--match` now applies to both test title and test filename.

- Removed the `--starting-port` command-line argument.
  You can use `-a starting-port=` instead.

- Selecting a `--job` that is empty now results in an error.
  This means that if you have more jobs than tests in your CI,
  your CI will fail.

- Skipping all tests with `--skip` or `--only` now results in an error.
  This makes those command-line arguments behave like other filters.

- Tests are now registered with the full value passed as
  `~__FILE__` to `Test.register`, instead of just the
  basename.

### New Features

- Added `?seed` to `Test.register` and the `--seed` command-line parameter
  to help control the determinism of randomness.

- Added `--log-worker-ids` which adds worker ids to logs when
  `--job-count` is more than 1.

- Added `--not-match` to deselect tests with a title that matches a
  regular expression.

- Added `--not-file` to deselect tests with a given filename.

- `--time` can now be passed along with `--from-record <record.json> --list` to
  pretty-print timings from previous executions.

- `--file FILE` now selects all tests registered from a source file
  that ends with `FILE`.

- Added `--not-file FILE` to deselect tests registered from a source
  file that ends with `FILE`.

- In `Cli`: added `_opt` variants for functions that retrieve custom arguments.

### Bug Fixes

- Fixed a bug where the log file does not contain logs from tests in
  the presence of `--job-count`.  In the presence of `--job-count N`
  and `--log-file FILE`, test results are now written to `FILE`, where
  as the logs from tests are written in a separate file per worker
  named `BASENAME-WORKER_ID.EXT`, as detailed in `--help`.

- Fixed a bug where a warning is not emitted when the argument to
  `--not-title` does not correspond to any known files.

- Fixed a bug where the list of selectors printed with an empty test
  selection would not contain `--not-title`.

- Remove unused argument `--starting-port`.

## Version 3.0.0

### Breaking Changes

- Argument `~output_file` of `Regression.register`
  is now optional and has been renamed into `?file`.
  Previously, `~output_file` was automatically prefixed by the value
  given to `--regression-dir`. Now, files are put in a directory
  named `expected` next to the test itself, and the default filename
  is a sanitized version of the test title.

- Removed the `--regression-dir` command-line parameter.

### New Features

- The `tezt` Dune library was split into `tezt.core` and `tezt`.
  Library `tezt.core` contains the parts that can run both on UNIX and using Node.js.
  It does not contain `Test.run` though so it cannot be used on its own.
  Library `tezt` is the UNIX backend. It also includes `tezt.core`, so
  this is not a breaking change.

- New library `tezt.js` is a partial backend for Node.js.
  Compared to `tezt`, it does not contain modules `Process`, `Temp` and `Runner`.

- Added `--resume` (short-hand: `-r`) and `--resume-file`,
  which allow to resume a previous run.
  For instance, if the previous run stopped after a failed test,
  and if that previous run was itself ran with `--resume` or `--resume-file`,
  resume from this run to avoid running the tests that already succeeded again.

- Added `--match` (short-hand: `-m`) to select tests with a title that match
  a regular expression.

- Added a `?timeout` argument to `Process.terminate` and `Process.clean_up`.
  These functions send `SIGTERM` to processes.
  If this timeout is reached without the process actually terminating,
  `Process.terminate` also sends `SIGKILL`.

- Added module `Diff` which allows to compare two sequences.
  It is used internally by the `Regression` module to compare test outputs
  between runs.

- Added module `Main` with function `Main.run`, which is the same as `Test.run`.
  In practice you can still use `Test.run`, which now delegates to `Main.run`.
  But `Test.run` is not available in `tezt.core`, only in `tezt` and `tezt.js`.
  This is not a breaking change since existing applications would use `tezt`,
  not `tezt.core` directly.

- Added `Base.project_root` which is the path to the root of the current dune project
  according to environment variable `DUNE_SOURCEROOT`, falling back to
  the current directory if unavailable.

- Added `Base.span` to split a list in two sublists given a predicate.

- Added `Base.rexf`, a short-hand for `rex @@ sf`.

- Added `Check.file_exists`, `Check.file_not_exists`,
  `Check.directory_exists` and `Check.directory_not_exists`.

- Added `Check.is_true` and `Check.is_false`.

- Added `Check.json` and `Check.json_u`, type definitions for `JSON.t`
  and `JSON.u` respectively.

- Added support for `int32` in the `JSON` module.

- Added `JSON.merge_objects`, `JSON.filter_map_object` and `JSON.filter_object`.

- Added `JSON.equal` and `JSON.equal_u`, equality predicates on `JSON.t`
  and `JSON.u` respectively.

- Added `Temp.set_pid`. The `Temp` module no longer calls `Unix.getpid` directly,
  this is done by `Test.run` instead, which calls `Temp.set_pid`.
  This allows backends where `Unix.getpid` cannot be used, like JS.

- Added `Test.run_with_scheduler`, and the `Test.SCHEDULER` signature.
  Added `Test.get_test_by_title` and `Test.run_one`.
  Those functions are used internally to provide different backends (UNIX / JS),
  but users usually would not have any use for them.

- Some fields in records obtained with `--record` became optional, with default values.
  New records may not be compatible with old versions of Tezt.

- Added module `Process_hooks` which contains the type definition for `Process.hooks`.

### Bug Fixes

- Fixed some cases where regression tests would crash instead of failing
  gracefully for some system errors.

- `Temp.clean_up` no longer follows symbolic links, it just deletes the links themselves.

- Fixed `--junit` which no longer worked when using `-j`.

- Fixed `--loop-count 0` which did not actually run zero loops.

- Fixed a bug where Tezt would exit prematurely without running tests
  when using `--on-unknown-regression-files delete` or `--on-unknown-regression-files fail`.

- Fixed a redundancy in the warning message when removing a non-empty
  temporary directories registered with the `Temp` module.

- Fixed some whitespace issues in `--help`.

## Older Versions

Tezt 2.0.0 was the first announced release and as such it had no changelog.
Tezt 1.0.0 was released in opam but was not announced.
