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
                  src/proto_alpha/lib_protocol/test/pbt/test_tickets.exe
    Subject:      Property-Based Tests for Tickets
*)

module Test_helpers = Lib_test.Qcheck_helpers
open Protocol.Alpha_context
open Ticket_generators

let balance_table_keys : Ticket_hash.t list Context_monad.t =
  Context_monad.lift_read @@ fun _ctxt -> Stdlib.failwith "TODO MERGE"
(* Ticket.all_keys ctxt *)

let rec traverse xs f =
  match xs with
  | [] -> Context_monad.return []
  | x :: xs -> Context_monad.map2 (fun x xs -> x :: xs) (f x) (traverse xs f)

let balance_table : (Ticket_hash.t * Z.t) list Context_monad.t =
  let open Monad.Syntax (Context_monad) in
  let* keys = balance_table_keys in
  let* kvs =
    traverse keys (fun key ->
        let* balance =
          Context_monad.lift_right @@ fun ctxt ->
          Ticket_balance.get_balance ctxt key
        in
        Context_monad.return
        @@ Option.fold ~none:[] ~some:(fun b -> [(key, b)]) balance)
  in
  Context_monad.return @@ List.concat kvs

let show_key_balance (_key : Ticket_hash.t) balance : string * string =
  let key =
    Stdlib.failwith "TODO MERGE"
    (*
    String.escaped @@ Format.kasprintf Fun.id "%a" AC.Ticket.pp_key key
    *)
  in
  let regexp = Str.regexp "\\\\00[0-9]" in
  let key = Str.global_replace regexp "" key in
  let balance = Z.to_string balance in
  (key, balance)

let compare_key_balance (k1, b1) (k2, b2) =
  match String.compare k1 k2 with
  | n when n <> 0 -> n
  | _ -> String.compare b1 b2

let normalize_balances (key_balances : (Ticket_hash.t * counter) list) :
    (string * string) list =
  List.filter_map
    (fun (key, balance) ->
      if Z.equal balance Z.zero then None
      else Some (show_key_balance key balance))
    key_balances
  |> List.sort compare_key_balance

(* TODO consolidate show_balance_table with similar code in Test_ticket_balance *)
let show_balance_table : (string * string) list -> string =
 fun kvs ->
  let show_rows kvs =
    let key_col_length =
      List.fold_left (fun mx (s, _) -> max mx (String.length s)) 0 kvs
    in
    let column align col_length s =
      let space =
        Stdlib.List.init (col_length - String.length s) (fun _ -> " ")
        |> String.concat ""
      in
      match align with
      | `Left -> Printf.sprintf "%s%s" s space
      | `Right -> Printf.sprintf "%s%s" space s
    in
    List.map
      (fun (k, v) ->
        Printf.sprintf
          "| %s  | %s |"
          (column `Left key_col_length k)
          (column `Right 8 v))
      kvs
    |> String.concat "\n"
  in
  show_rows (("Token x Content x Owner", "Balance") :: kvs)

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

let pp_bal f kvs_balance =
  Format.pp_print_string f (show_balance_table @@ normalize_balances kvs_balance)

let eq_bal a b =
  0
  = Stdlib.compare
      (show_balance_table @@ normalize_balances a)
      (show_balance_table @@ normalize_balances b)

let qcheck_wrap xs =
  List.map (fun (x, y, z) -> (x, y, fun a -> Lwt.return @@ z a))
  @@ Test_helpers.qcheck_wrap xs

let test_storage_unchanged =
  qcheck_wrap
    [
      qcheck_make_stateful
        ~name:"storage unchanged"
        ~generator:
          (let open Monad.Syntax (Context_gen) in
          let+ storage = ex_val_generator ~allow_bigmap:false ~max_depth:3
          and+ param = Context_gen.return (Ex_val (Unit_t, ())) in
          (storage, param))
        ~property:(fun (ex_storage, ex_param) ->
          let open Monad.Syntax (Context_monad) in
          let (Ex_val (storage_type, storage)) = ex_storage in
          let (Ex_val (arg_type, arg)) = ex_param in
          let alice = default_step_constants.source in
          let* old_balances = balance_table in
          let* () =
            Context_monad.lift_unit @@ fun ctxt ->
            Protocol.Ticket_scanner.type_has_tickets ctxt arg_type
            >>?= fun (arg_type_tickets, ctxt) ->
            Protocol.Ticket_scanner.type_has_tickets ctxt storage_type
            >>?= fun (storage_type_has_tickets, ctxt) ->
            Protocol.Ticket_accounting.ticket_diffs
              ctxt
              ~arg_type_has_tickets:arg_type_tickets
              ~arg
              ~storage_type_has_tickets
              ~old_storage:storage
              ~new_storage:storage
              ~lazy_storage_diff:[]
            >>=? fun (ticket_map, ctxt) ->
            Protocol.Ticket_accounting.update_ticket_balances
              ctxt
              ~self:alice
              ~ticket_diffs:ticket_map
              []
            >|=? fun (_, ctxt) -> ctxt
          in
          let* new_balances = balance_table in
          (* No tickets were passed and storage is unchanged, so
             the balance table should be unchanged.
          *)
          Context_monad.return
          @@ Test_helpers.qcheck_eq
               ~eq:eq_bal
               ~pp:pp_bal
               old_balances
               new_balances);
    ]

let test_drop_from_strict =
  qcheck_wrap
    [
      qcheck_make_stateful
        ~name:"drop from strict storage"
        ~generator:
          (let open Monad.Syntax (Context_gen) in
          let* _ =
            Context_gen.lift @@ Context_monad.lift_unit
            @@ fun ctxt ->
            Lwt.( >>= ) (Lwt_io.printl "TODO DEBUG new gen") (fun () ->
                return ctxt)
          in
          let* param = ex_val_generator ~allow_bigmap:false ~max_depth:2 in
          let* storage = ex_val_generator ~allow_bigmap:false ~max_depth:2 in
          Context_gen.return (storage, param))
        ~property:(fun (ex_storage, ex_param) ->
          let open Monad.Syntax (Context_monad) in
          let (Ex_val (storage_type, storage)) = ex_storage in
          let (Ex_val (arg_type, arg)) = ex_param in
          let alice = default_step_constants.source in
          let* () =
            Context_monad.lift_unit @@ fun ctxt ->
            Protocol.Ticket_scanner.type_has_tickets ctxt arg_type
            >>?= fun (arg_type_tickets, ctxt) ->
            Protocol.Ticket_scanner.type_has_tickets
              ctxt
              (option_t storage_type)
            >>?= fun (storage_type_has_tickets, ctxt) ->
            Protocol.Ticket_accounting.ticket_diffs
              ctxt (*~update_storage:return*)
              ~arg_type_has_tickets:arg_type_tickets
              ~arg
              ~storage_type_has_tickets
              ~old_storage:(Some storage)
              ~new_storage:None
              ~lazy_storage_diff:[]
            >>=? fun (ticket_map, ctxt) ->
            Protocol.Ticket_accounting.update_ticket_balances
              ctxt
              ~self:alice
              ~ticket_diffs:ticket_map
              []
            >|=? fun (_, ctxt) -> ctxt
          in
          let* new_balances = balance_table in
          (* Nothing is transferred or stored, so the balance
             table should be empty *)
          Context_monad.return
          @@ Test_helpers.qcheck_eq (* TODO factor/outmove up: *)
               ~eq:eq_bal
               ~pp:pp_bal
               []
               new_balances);
    ]

let test_drop_lazy =
  qcheck_wrap
    [
      qcheck_make_stateful
        ~name:"drop all tickets from lazy storage"
        ~generator:
          (let open Monad.Syntax (Context_gen) in
          let+ storage = ex_val_generator ~allow_bigmap:true ~max_depth:2
          and+ param = ex_val_generator ~allow_bigmap:true ~max_depth:2 in
          (storage, param))
        ~property:(fun (ex_storage, ex_param) ->
          let open Monad.Syntax (Context_monad) in
          let (Ex_val (storage_type, storage)) = ex_storage in
          let (Ex_val (arg_type, arg)) = ex_param in
          let alice = default_step_constants.source in
          let arg_type = arg_type in
          let storage_type = option_t storage_type in
          let old_storage = Some storage in
          let* (new_storage, lazy_storage_diff, operations) =
            Context_monad.lift_left @@ fun ctxt ->
            Script_ir_translator.collect_lazy_storage ctxt arg_type arg
            >>?= fun (to_duplicate, ctxt) ->
            Script_ir_translator.collect_lazy_storage
              ctxt
              storage_type
              old_storage
            >>?= fun (to_update, ctxt) ->
            (*
                trace
                  (Runtime_contract_error (step_constants.self, script_code))
                  (interp logger (ctxt, step_constants) code (arg, old_storage))
                >>=? fun ((operations, new_storage), ctxt) ->
                *)
            let operations = Protocol.Script_list.empty in
            let new_storage = None in
            Script_ir_translator.extract_lazy_storage_diff
              ctxt
              Script_ir_translator.Readable
              ~temporary:false
              ~to_duplicate
              ~to_update
              storage_type
              new_storage
            >>=? fun (_storage, lazy_storage_diff, ctxt) ->
            let (_ops, op_diffs) = List.split operations.elements in
            let lazy_storage_diff =
              match
                List.flatten
                  (List.map
                     (Option.value ~default:[])
                     (op_diffs @ [lazy_storage_diff]))
              with
              | [] -> None
              | diff -> Some diff
            in
            return
              ( ctxt,
                ( new_storage,
                  List.concat @@ Option.to_list lazy_storage_diff,
                  operations ) )
          in
          let* () =
            Context_monad.lift_unit @@ fun ctxt ->
            Protocol.Ticket_scanner.type_has_tickets ctxt arg_type
            >>?= fun (arg_type_tickets, ctxt) ->
            Protocol.Ticket_scanner.type_has_tickets ctxt storage_type
            >>?= fun (storage_type_has_tickets, ctxt) ->
            Protocol.Ticket_accounting.ticket_diffs
              ctxt (*~update_storage:return*)
              ~arg_type_has_tickets:arg_type_tickets
              ~arg
              ~storage_type_has_tickets
              ~old_storage
              ~new_storage
              ~lazy_storage_diff
            >>=? fun (ticket_map, ctxt) ->
            Protocol.Ticket_accounting.update_ticket_balances
              ctxt
              ~self:alice
              ~ticket_diffs:ticket_map
              operations.elements
            >|=? fun (_, ctxt) -> ctxt
            (*Protocol.Ticket_accounting.update_ticket_balances
              ctxt
              ~self:alice
              ~update_storage:return
              ~arg_type
              ~arg
              ~storage_type
              ~old_storage
              ~new_storage
              ~lazy_storage_diff
              ~operations*)
          in
          let* new_balances = balance_table in
          (* Nothing is transferred or stored, so the balance
             table should be empty *)
          Context_monad.return
          @@ Test_helpers.qcheck_eq (* TODO factor/outmove up: *)
               ~eq:eq_bal
               ~pp:pp_bal
               []
               new_balances);
    ]

(* TODO: Fix tests above *)
let tests = List.concat []

let () =
  Lwt_main.run
  @@ Alcotest_lwt.run "protocol > pbt > test_tickets" [("Tez_repr", tests)]
