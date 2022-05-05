(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2022 Trili Tech, <contact@trili.tech>                       *)
(*                                                                           *)
(* Permission is hereby granted, free of charge, to any person obtaining a   *)
(* copy of this software and associated documentation files (the "Software"),*)
(* to deal in the Software without restriction, including without limitation *)
(* the rights to use, copy, modify, merge, publish, distribute, sublicense,  *)
(* and/or sell copies of the Software, and to permit persons to whom the     *)
(* Software is furnished to do so, subject to the following conditions:      *)
(*                                                                           *)
(* The above copyright notice and this permission notice shall be included   *)
(* in all copies or substantial portions of the Software.                    *)
(*                                                                           *)
(* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR*)
(* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,  *)
(* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL   *)
(* THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER*)
(* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING   *)
(* FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER       *)
(* DEALINGS IN THE SOFTWARE.                                                 *)
(*                                                                           *)
(*****************************************************************************)

(** Testing
    -------
    Component:    Protocol Library
    Invocation:   dune exec \
                  src/proto_alpha/lib_protocol/test/pbt/test_ticket_generators.exe
    Subject:      Property-Based Tests for Tickets
*)

module Test_helpers = Lib_test.Qcheck_helpers
open Protocol.Alpha_context
open Ticket_generators

(** Unparse interpreter representation to Michelson AST. *)
let unparse_data_readable :
    ('a, 'b) Script_typed_ir.ty -> 'a -> Script.node Context_monad.t =
 fun ty x ->
  Context_monad.lift_right (fun ctxt ->
      Script_ir_translator.unparse_data ctxt Script_ir_translator.Readable ty x)

(** Unparse interpreter representation to a string. *)
let unparse_data_to_string :
    ('a, 'b) Script_typed_ir.ty -> 'a -> string Context_monad.t =
 fun ty x ->
  let string_of_node (n : Script.node) : string =
    let c = Micheline.strip_locations n in
    Format.kasprintf
      Fun.id
      "%a"
      Micheline_printer.print_expr
      (Micheline_printer.printable
         Protocol.Michelson_v1_primitives.string_of_prim
         c)
  in
  let open Monad.Syntax (Context_monad) in
  let* node = unparse_data_readable ty x in
  Context_monad.return @@ string_of_node node

(** Unparse and parse back a Michelson type. *)
let unparse_and_parse ty =
  Context_monad.lift_right @@ fun ctxt ->
  let open Lwt_result_syntax in
  let*? (node, ctxt) =
    Script_ir_translator.unparse_ty ~loc:Micheline.dummy_location ctxt ty
  in
  Lwt.return
  @@ Script_ir_translator.parse_ty
       ctxt
       ~legacy:false
       ~allow_lazy_storage:true
       ~allow_operation:false
       ~allow_contract:true
       ~allow_ticket:true
       node

(** A fixed seed used to test the generator framework itself. *)
let test_seed = 5471827389070247L

(** Test that a stateless generator produces some predetermined output.
    Equality is checked as per the given testable.
    *)
let test_stateless :
    type a.
    string -> a Alcotest.testable -> a Gen.t -> a -> unit Alcotest_lwt.test_case
    =
 fun msg testable gen expected ->
  Tztest.tztest msg `Quick @@ fun () ->
  return
  @@ Alcotest.check
       testable
       "generated value"
       expected
       (Identity.run (gen @@ Lib_test.Random_pure.of_seed test_seed))

(** Test that a stateful generator produces some predetermined output in a fresh context.
    Equality is checked as per the given testable.
    *)
let test_stateful :
    type a.
    string ->
    a Alcotest.testable ->
    a Context_gen.t ->
    a ->
    unit Alcotest_lwt.test_case =
  let test_context () =
    let ( let* ) m f = m >>=? f in
    let* (b, _) = Context.init_n 3 () in
    let* v = Incremental.begin_construction b in
    return (Incremental.alpha_ctxt v)
  in
  fun msg testable gen expected ->
    Tztest.tztest msg `Quick @@ fun () ->
    let ( let* ) = Lwt.( >>= ) in
    let* ctxt_res = test_context () in
    match ctxt_res with
    | Error _ -> Stdlib.failwith "Could not create context"
    | Ok ctxt ->
        let* (_ctxt, actual) =
          Context_monad.run_lwt_exn ctxt
          @@ (fun f -> f @@ Lib_test.Random_pure.of_seed test_seed)
          @@ gen
        in
        return @@ Alcotest.check testable "generated value" expected actual

(** Test that a stateful generator produces some predetermined output in a fresh context.
    The result is converted to a Michelson literal and cheked against the given string.
  *)
let test_stateful_ty :
    type a. (a, _) Script_typed_ir.ty -> string -> unit Alcotest_lwt.test_case =
 fun ty expected ->
  let open Monad.Syntax (Context_gen) in
  test_stateful
    (to_string (Ex_ty ty))
    Alcotest.string
    (let* big_map = ty_generator @@ Script_typed_ir.Ty_ex_c ty in
     Context_gen.lift @@ unparse_data_to_string ty big_map)
    expected

let test_context () =
  let ( let* ) m f = m >>=? f in
  let* (b, _) = Context.init_n 5 () in
  let* v = Incremental.begin_construction b in
  return @@ Incremental.alpha_ctxt v

module Alpha_test = struct
  exception Could_not_create_context

  (** Run an [Context_monad] computation in a default (empty) context, and return
        the final context. Fails on errors.

        Useful for testing.
     *)
  let run_in_default_context_exn :
      type a. a Context_monad.t -> (context * a) Lwt.t =
   fun h ->
    let ( let* ) = Lwt.( >>= ) in
    let* ctxt_res = test_context () in
    match ctxt_res with
    | Error _e -> raise Could_not_create_context
    | Ok ctxt -> Context_monad.run_lwt_exn ctxt h
end

(* TODO make this private, should only be used from qcheck_make_stateful, as
    it calls into expensive context setup, and therefore neeeds smaller count/max_gen
    parameters than QCheck.Test.make defaults.
   *)

(** Convert a an [Context_gen] to a [QCheck.arbitrary], for passing to [QCheck.make].

    {i Warning:} Uses [Lwt_main.run] internally. Running this inside another [Lwt]
    computation will fail.
 *)
let to_arb_exn (gen : 'a Context_gen.t) : (context * 'a) QCheck.arbitrary =
  QCheck.make (fun g ->
      Lwt_main.run @@ Alpha_test.run_in_default_context_exn
      @@ (Context_gen.to_qcheck_gen gen) g)

(* TODO make sure all uses of qcheck_eq should pass a comparator, or else we
   fall back on Stdlib. *)
let qcheck_make_stateful :
    name:string ->
    generator:'a Context_gen.t ->
    property:('a -> bool Context_monad.t) ->
    QCheck.Test.t =
 fun ~name ~generator ~property ->
  QCheck.Test.make
  (* Note: QCheck defaults as of 0.17:
       count=100
       max_gen=count+200
       max_fail=1
  *)
    ~count:(15 + 100)
    ~max_gen:(20 + 100)
    ~name
    (to_arb_exn generator)
    (*
                  Ugly solution: use Lwt_main.run.

                  Nice solution: make a version of QCheck.Test
                  parameterized on the effect type.
               *)
    (fun (ctxt, ex) ->
      Lwt_main.run
      @@ Lwt.map (fun x -> snd x)
      @@ Context_monad.run_lwt_exn ctxt (property ex))

let pp_ir_ex_ty f (Script_ir_translator.Ex_ty ty) =
  let s = to_string @@ Ex_ty ty in
  Format.pp_print_string f s

let qcheck_wrap xs =
  List.map (fun (x, y, z) -> (x, y, fun a -> Lwt.return @@ z a))
  @@ Test_helpers.qcheck_wrap xs

let test_stateless =
  [
    test_stateless "()" Alcotest.unit (Gen.return ()) ();
    test_stateless
      "string"
      Alcotest.string
      Gen.string_readable
      "GSCFNIXYOJUJWXPBSA";
    test_stateless
      "list bool"
      (Alcotest.list Alcotest.bool)
      (Gen.small_list Gen.bool)
      [true; true; false; false; false; true; false];
  ]

let test_return_generators =
  qcheck_wrap
    [
      QCheck.Test.make
        ~name:"return generator works"
        (QCheck.make (Gen.to_qcheck_gen (Gen.return "hiha")))
        (fun x -> Test_helpers.qcheck_eq (Identity.run x) "hiha");
    ]

let test_stateful =
  [
    test_stateful_ty Unit_t "Unit";
    test_stateful_ty (map_t Unit_t Unit_t) "{ Elt Unit Unit }";
    test_stateful_ty (map_t Bool_t Bool_t) "{ Elt False True ; Elt True True }";
    test_stateful_ty (big_map_t Unit_t Unit_t) "{ Elt Unit Unit }";
    test_stateful_ty
      (big_map_t Bool_t Unit_t)
      "{ Elt False Unit ; Elt True Unit }";
    test_stateful_ty
      (big_map_t Unit_t @@ big_map_t Unit_t Unit_t)
      "{ Elt Unit { Elt Unit Unit } }";
  ]

let test_sanity =
  qcheck_wrap
    [
      qcheck_make_stateful
        ~name:"trivial generator works"
        ~generator:(Context_gen.return @@ Ex_val (Unit_t, ()))
        ~property:(fun ex ->
          let open Monad.Syntax (Context_monad) in
          let (Ex_val (ty, x)) = ex in
          let* str = unparse_data_to_string ty x in
          Context_monad.return
          @@ Test_helpers.qcheck_eq ~pp:Format.pp_print_string str str);
      qcheck_make_stateful
        ~name:"ex_val_generator works"
        ~generator:(ex_val_generator ~allow_bigmap:true ~max_depth:5)
        ~property:(fun ex ->
          let open Monad.Syntax (Context_monad) in
          let (Ex_val (ty, x)) = ex in
          let* str = unparse_data_to_string ty x in
          Context_monad.return
          @@ Test_helpers.qcheck_eq ~pp:Format.pp_print_string str str);
      qcheck_make_stateful
        ~name:"ex_ty_generator works"
        ~generator:(ex_ty_generator ~allow_bigmap:true ~max_depth:5)
        ~property:(fun ex ->
          let str = to_string ex in
          Context_monad.return
          @@ Test_helpers.qcheck_eq ~pp:Format.pp_print_string str str);
      qcheck_make_stateful
        ~name:"parsing and unparsing leads to identity"
        ~generator:(ex_ty_generator ~allow_bigmap:false ~max_depth:2)
        ~property:(fun ex ->
          let open Monad.Syntax (Context_monad) in
          let (Ex_ty ty) = ex in
          let expected = Script_ir_translator.Ex_ty ty in
          let* actual = unparse_and_parse ty in
          Context_monad.return
          @@ Test_helpers.qcheck_eq ~pp:pp_ir_ex_ty expected actual);
    ]

let tests =
  List.concat
    [test_stateless; test_return_generators; test_stateful; test_sanity]

let () =
  Lwt_main.run
  @@ Alcotest_lwt.run "protocol > pbt > test_tickets" [("Tez_repr", tests)]
