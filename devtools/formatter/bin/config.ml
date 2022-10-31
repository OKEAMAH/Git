open Fmt
open Config_helpers

(** Configuration for the formatting of all files in the repository. *)

(*
   let known_authors =
     [
       ("Nomadic Labs <contact@nomadic-labs.com>", 2019, 2099);
       ("Trili Tech <contact@trili.tech>", 2022, 2099);
     ]

   let autofix_copyright_line =
     let open F in
     let format = ([Exact "Copyright (c) "; Years; Exact " "; AnyText] : _ line) in
     let map ((), (years, ((), (who, ())))) =
       fix_copyright known_authors years who
     in
     let unmap (years, who) = ((), (years, ((), (who, ())))) in
     LMap {format; map; unmap}

   let sorted_copyright_lines =
     let open F in
     let format = RepeatLine autofix_copyright_line in
     let map years_who_list = List.sort compare years_who_list in
     let unmap years_who_list = years_who_list in
     FMap {format; map; unmap} *)

(* let copyright_lines =
   F.RepeatLine [Exact "Copyright (c) "; Years; Exact " "; AnyText] *)

(** General open-source license for Octez. *)
let open_source_license_header =
  Format_header
    (CommentBlock
       [
         OrSuggest Fill;
         OrSuggest (Line []);
         RepeatLine [AnyText];
         (* Line (Exact "Open Source License");
            copyright_lines; *)
         Line [];
         Paragraph;
         Paragraph;
         Paragraph;
         (* ExactParagraph
            {|Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:|}; *)
         (* ExactParagraph
            {|The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.|}; *)
         (* ExactParagraph
            {|THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.|}; *)
         OrSuggest Fill;
       ])

(** Line at which the copyright header starts. First line is 1. *)
let start_line = mk ~name:"start line" ~default:1 [(G "*.sh", 2)]

(** Start/end of a single-line comment. *)
let comment_start_end =
  mk
    ~name:"comment start/end"
    [(G "*.ml*", ("(*", "*)")); (G "*.sh", ("#", "")); (G "*.js", ("//", ""))]

(** Comment line length. *)
let comment_line_length = mk ~name:"comment line length" ~default:80 []

(** Ignored files. *)
let ignore =
  mk_set
    [
      (* .git objects *)
      G ".git";
      (* Files mentioned in .gitignore files are treated by {!Seq.readdir_recursive}. *)
      (* Human-readable files that cannot contain comments. *)
      Gs ["CHANGES.rst"; "LICENSE"; "README"; "*.md"; "*.rst"; "*.txt"];
      (* Machine-readable files that cannot contain comments. *)
      Gs
        [
          "*.json";
          ".npmrc";
          "*.patch";
          "*.png";
          "*.wasm";
          "poetry.lock";
          "pytest.ini";
          "rust-toolchain";
          "scripts/alphanet_version";
          "script-inputs/";
          "src/proto_*/lib_protocol/contracts/*.bin";
          "src/lib_base/test/points.ok";
          "src/lib_base/test/points.ko";
          "src/lib_client_base/gen/bip39_english.txt";
          "src/lib_crypto_dal/test/shard_proofs_precomp";
          "src/lib_protocol_compiler/final_protocol_versions";
        ];
      (* Generated files we do not care about. *)
      Gs
        [
          "*.out";
          "pyproject.toml";
          "tests_python/test-results.xml";
          "src/lib_protocol_environment/sigs/v*.ml";
          "src/lib_time_measurement/ppx/test/invalid/test_*_output";
          "src/proto_*/lib_protocol/test/integration/michelson/patched_contracts/expr*.diff";
          "tezt/self_tests/*.t";
        ];
      (* Frozen protocols. *)
      G "src/proto_0*/lib_protocol/*.ml*";
      (* Family of files we MAY want to do, but later. *)
      Gs
        [
          "dune";
          ".gitignore";
          "TEZOS_PROTOCOL";
          "Makefile";
          "*.html";
          "*.js";
          "*.mld";
          "*.mll";
          "*.mly";
          ".ocamlformat*";
          "*.opam";
          "*.ott";
          "*.py";
          "*.sh";
          "*.svg";
          "*.tex";
          "*.tz";
          "*.xml";
          "*.yaml";
          "*.yml";
          "devtools/";
          "opam/";
          "src/lib_webassembly/";
        ];
      Gs
        [
          "src/proto_*/lib_benchmark/test/test_distribution.ml";
          "src/proto_*/lib_delegate/test/main.ml";
          "src/proto_*/lib_delegate/baking_configuration.mli";
          "src/proto_*/lib_protocol/contracts/*.mligo";
          "src/proto_*/lib_protocol/liquidity_baking_*.ml";
          "src/proto_*/lib_protocol/test/helpers/script_big_map.ml";
          "src/proto_*/lib_protocol/test/helpers/nonce.ml";
          "src/proto_*/lib_protocol/test/helpers/ticket_helpers.ml";
          "src/proto_*/lib_protocol/test/integration/validate/*.ml";
          "src/proto_*/lib_protocol/test/unit/test_time_repr.ml";
        ];
      Gs
        [
          "src/lib_protocol_environment/sigs/v*.in.ml";
          "src/lib_protocol_environment/sigs/v*/bytes.mli";
          "src/lib_protocol_environment/sigs/v*/char.mli";
          "src/lib_protocol_environment/sigs/v*/either.mli";
          "src/lib_protocol_environment/sigs/v*/format.mli";
          "src/lib_protocol_environment/sigs/v*/hex.mli";
          "src/lib_protocol_environment/sigs/v*/int32.mli";
          "src/lib_protocol_environment/sigs/v*/int64.mli";
          "src/lib_protocol_environment/sigs/v*/list.mli";
          "src/lib_protocol_environment/sigs/v*/lwt.mli";
          "src/lib_protocol_environment/sigs/v*/lwt_list.mli";
          "src/lib_protocol_environment/sigs/v*/map.mli";
          "src/lib_protocol_environment/sigs/v*/pervasives.mli";
          "src/lib_protocol_environment/sigs/v*/q.mli";
          "src/lib_protocol_environment/sigs/v*/sapling.mli";
          "src/lib_protocol_environment/sigs/v*/set.mli";
          "src/lib_protocol_environment/sigs/v*/string.mli";
          "src/lib_protocol_environment/sigs/v*/z.mli";
        ];
      (* Specific files we MAY want to do, but later. *)
      Gs
        [
          "CODEOWNERS";
          "Dockerfile";
          ".dockerignore";
          ".pylintrc";
          "shell.nix";
          "docs/_redirects";
          "emacs/michelson-mode.el";
          "manifest/JSON_AST.ml";
          "manifest/tezos_protocol.ml";
          "scripts/ci/docker.env";
          "scripts/gen-genesis/gen_genesis.ml";
          "src/lib_base/genesis.ml*";
          "src/lib_base/unix/protocol_files.ml*";
          "src/lib_benchmark/lib_micheline_rewriting/custom_weak.ml";
          "src/lib_clic/examples/clic_example.ml";
          "src/lib_clic/unix/scriptable.ml";
          "src/lib_client_base/bip39.ml";
          "src/lib_client_base/pbkdf.ml*";
          "src/lib_client_base/gen/bip39_generator.ml";
          "src/lib_client_base/test/bip39_tests.ml";
          "src/lib_client_base/test/pbkdf_tests.ml";
          "src/lib_crypto/hacl.mli";
          "src/lib_crypto/test/key_encoding_vectors.ml";
          "src/lib_crypto/test/test_run.ml";
          "src/lib_crypto_dal/test/test_dal_cryptobox.ml";
          "src/lib_hacl/hacl.ml";
          "src/lib_hacl/gen/gen0.ml";
          "src/lib_hacl/test/test.ml";
          "src/lib_hacl/test/vectors_p256.ml";
          "src/lib_micheline/test/test_parser.mli";
          "src/lib_p2p/test/test_p2p_logging.ml";
          "src/lib_proxy/logger.ml*";
          "src/lib_proxy/proxy_events.ml";
          "src/lib_protocol_compiler/bin/cmis_of_cma.ml";
          "src/lib_protocol_environment/ppinclude/ppinclude.ml";
          "src/lib_test/random_pure.ml";
          "src/lib_time_measurement/ppx/test/invalid/test_*_input.ml";
          "src/lib_time_measurement/ppx/test/valid/*.ml";
          "src/proto_demo_counter/lib_protocol/proto_operation.ml";
          "src/tooling/node_wrapper.ml";
          "src/tooling/opam-lint/**.ml";
          "tests_python/mypy.ini";
          "tezt/records/update.ml";
        ];
    ]

(* TODO: check that all the patterns above match at least one file. *)

(** File format. *)
let format = mk ~name:"file format" ~default:open_source_license_header []
