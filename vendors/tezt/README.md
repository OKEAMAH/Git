# Tezt

Tezt (pronounced "tezty", as in "tasty" with a "z") is a test framework for OCaml.
It is well suited for writing and executing unit, integration and
regression tests. It integrates well with continuous integration (CI).

## API Documentation

The [API documentation](https://nomadic-labs.gitlab.io/tezt/dev/tezt/Tezt/index.html)
contains an introduction to Tezt as well as documentation for all modules.
It is generated from `lib/tezt.ml`.

## Getting Started

### Install

Install with [opam](https://opam.ocaml.org/):
```
opam install tezt
```

### Write a Test

Create a file such as `test/main.ml`:
```ocaml
(* [Tezt] and its submodule [Base] are designed to be opened.
   [Tezt] is the main module of the library and it only contains submodules,
   such as [Test] which is used below.
   [Tezt.Base] contains values such as [unit] which is used below. *)
open Tezt
open Tezt.Base

(* Register as many tests as you want like this. *)
let () =
  Test.register
    (* [~__FILE__] contains the name of the file in which the test is defined.
       It allows to select tests to run based on their filename. *)
    ~__FILE__
    (* Titles uniquely identify tests so that they can be individually selected. *)
    ~title: "demo"
    (* Tags are another way to group tests together to select them. *)
    ~tags: [ "math"; "addition" ]
  @@ fun () ->
  (* Here is the actual test. *)
  if 1 + 1 <> 2 then Test.fail "expected 1 + 1 = 2, got %d" (1 + 1);
  (* Here is another way to write the same test. *)
  Check.((1 + 1 = 2) int) ~error_msg: "expected 1 + 1 = %R, got %L";
  Log.info "Math is safe today.";
  (* [unit] is [Lwt.return ()]. *)
  unit

(* Call the main function of Tezt so that it actually runs your tests. *)
let () = Test.run ()
```

Then create a `test/dune` file:
```
(test (name main) (libraries tezt))
```

You can now run your test with `dune runtest`.
However `dune runtest` is limited because you cannot pass command-line arguments.
Usually, you would instead run something like:
```
dune exec test/main.exe -- -i
```

This should show you:
```
[09:04:06.395] Math is safe today.
[09:04:06.395] [SUCCESS] (1/1) demo
```

The `-i` flag is a short-hand for `--info` and sets the log level so that
you can see the result of the call to `Log.info`.

To see the list of command-line options, in particular how to select tests
from the command-line, how to run them in parallel and how to produce reports, run:
```
dune exec test/main.exe -- --help
```
