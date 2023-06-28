(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2023 Nomadic Labs. <contact@nomadic-labs.com>               *)
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
    Component:    Shell (Prevalidator)
    Invocation:   dune exec src/lib_shell/test/main.exe \
                  -- --file test_prevalidator.ml
    Subject:      Unit tests the Prevalidator APIs
*)

let register_test ~title ~additional_tags =
  Test.register
    ~__FILE__
    ~title:("Shell: Prevalidator: " ^ title)
    ~tags:(["mempool"; "prevalidator"] @ additional_tags)

module Protocol_accept_all :
  Tezos_protocol_environment.PROTOCOL
    with type operation_data = unit
     and type operation_receipt = unit
     and type validation_state = unit
     and type application_state = unit = struct
  open Tezos_protocol_environment.Internal_for_tests
  include Environment_protocol_T_test.Mock_all_unit

  let begin_validation _ctxt _chain_id _mode ~predecessor:_ ~cache:_ =
    Lwt_result_syntax.return_unit

  module Mempool = struct
    include Mempool

    let init _ _ ~head_hash:_ ~head:_ ~cache:_ = Lwt_result.return ((), ())

    let add_operation ?check_signature:_ ?conflict_handler:_ _vi t (_oph, _op) =
      Lwt_result_syntax.return (t, Mempool.Added)
  end
end

module Protocol_reject_all :
  Tezos_protocol_environment.PROTOCOL
    with type operation_data = unit
     and type operation_receipt = unit
     and type validation_state = unit
     and type application_state = unit = struct
  open Tezos_protocol_environment.Internal_for_tests
  include Environment_protocol_T_test.Mock_all_unit

  let begin_validation _ctxt _chain_id _mode ~predecessor:_ ~cache:_ =
    Lwt_result_syntax.return_unit

  module Mempool = struct
    include Mempool

    let init _ _ ~head_hash:_ ~head:_ ~cache:_ = Lwt_result.return ((), ())

    let add_operation ?check_signature:_ ?conflict_handler:_ _vi t (_oph, _op) =
      Lwt_result_syntax.return (t, Mempool.Unchanged)
  end
end

module MakeFilter (Proto : Tezos_protocol_environment.PROTOCOL) :
  Shell_plugin.FILTER
    with type Proto.operation_data = Proto.operation_data
     and type Proto.operation = Proto.operation
     and type Proto.Mempool.t = Proto.Mempool.t = Shell_plugin.No_filter (struct
  let hash = Protocol_hash.zero

  include Proto

  let complete_b58prefix _ = assert false
end)

let create_chain_db () =
  Lwt_utils_unix.with_tempdir "tezos_test_" @@ fun test_dir ->
  let open Lwt_result_syntax in
  let*! store = Shell_test_helpers.init_chain test_dir in
  let* p2p =
    Shell_test_helpers.init_mock_p2p Distributed_db_version.Name.zero
  in
  let db = Distributed_db.create store p2p in
  let chain_store = Store.(main_chain_store store) in
  let callback =
    P2p_reader.
      {
        notify_branch = (fun _ _ -> ());
        notify_head = (fun _ _ _ _ -> ());
        disconnection = (fun _ -> ());
      }
  in
  return (Distributed_db.activate db chain_store callback)

let create_prevalidator ~(accept_operations : bool) chain_db =
  let limits = Shell_limits.default_limits.prevalidator_limits in
  Prevalidator.create
    limits
    (if accept_operations then (module MakeFilter (Protocol_accept_all))
    else (module MakeFilter (Protocol_reject_all)))
    chain_db

let check_operation_db_length chain_db expected =
  let operation_db = Distributed_db.information chain_db in
  let length = operation_db.operation_db.table_length in
  if length <> expected then
    Test.fail
      "DDB Operation table was expected to have %d element in it, found %d"
      expected
      length
  else Log.warn "Operation_db length:%d" length

let create_dummy_operation () =
  let branch = Shell_test_helpers.genesis_block_hash in
  let proto = Bytes.of_string "" in
  Operation.{shell = {branch}; proto}

(* Test that the prevalidator shutdown does not clear the ddb operation table *)
let test_shutdown () =
  let open Lwt_result_syntax in
  let* chain_db = create_chain_db () in
  let* prevalidator = create_prevalidator ~accept_operations:true chain_db in
  check_operation_db_length chain_db 0 ;
  let op = create_dummy_operation () in
  let* () = Prevalidator.inject_operation prevalidator ~force:false op in
  check_operation_db_length chain_db 1 ;
  let*! () = Prevalidator.shutdown prevalidator in
  check_operation_db_length chain_db 1 ;
  return_unit

(* Test that at prevalidator start up, leftover operations in the DDB are
   handled *)
let test_clear_leftover () =
  let open Lwt_result_syntax in
  let* chain_db = create_chain_db () in
  let* prevalidator = create_prevalidator ~accept_operations:true chain_db in
  check_operation_db_length chain_db 0 ;
  let op = create_dummy_operation () in
  let* () = Prevalidator.inject_operation prevalidator ~force:false op in
  check_operation_db_length chain_db 1 ;
  let*! () = Prevalidator.shutdown prevalidator in
  check_operation_db_length chain_db 1 ;

  let* prevalidator = create_prevalidator ~accept_operations:false chain_db in
  let branch = Shell_test_helpers.genesis_block_hash in
  let* () =
    Prevalidator.flush
      prevalidator
      Chain_validator_worker_state.Head_increment
      branch
      Block_hash.Set.empty
      Operation_hash.Set.empty
  in
  check_operation_db_length chain_db 0 ;
  return_unit

let wrap_test f =
  let open Lwt_syntax in
  let* res = f () in
  match res with
  | Ok _ -> unit
  | Error err -> Test.fail "Error: %a !" pp_print_trace err

(* Test that the prevalidator.shutdown does not clear the ddb . *)
let () =
  ( register_test
      ~title:"shutdown does not clear the ddb operation table"
      ~additional_tags:["ddb"; "table"]
  @@ fun () -> wrap_test test_shutdown ) ;
  register_test
    ~title:"leftover operations in the ddb are handle at prevalidator startup"
    ~additional_tags:["ddb"; "table"; "handle"]
  @@ fun () -> wrap_test test_clear_leftover
