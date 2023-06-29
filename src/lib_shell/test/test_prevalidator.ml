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

let wrap_test f =
  let open Lwt_syntax in
  let* res = f () in
  match res with
  | Ok _ -> unit
  | Error err -> Test.fail "Error: %a !" pp_print_trace err

let register_test ~title ~additional_tags f =
  Test.register
    ~__FILE__
    ~title:("Shell: Prevalidator: " ^ title)
    ~tags:(["mempool"; "prevalidator"] @ additional_tags)
  @@ fun () -> wrap_test f

module type Add_operation_result = sig
  open Tezos_protocol_environment.Internal_for_tests.Environment_protocol_T_test
       .Mock_all_unit
       .Mempool

  val return : t -> (t * add_result, add_error) result
end

module Added : Add_operation_result = struct
  let return t =
    Ok
      ( t,
        Tezos_protocol_environment.Internal_for_tests
        .Environment_protocol_T_test
        .Mock_all_unit
        .Mempool
        .Added )
end

module Unchanged : Add_operation_result = struct
  let return t =
    Ok
      ( t,
        Tezos_protocol_environment.Internal_for_tests
        .Environment_protocol_T_test
        .Mock_all_unit
        .Mempool
        .Unchanged )
end

module Branch_refused : Add_operation_result = struct
  let return _t =
    Error
      (Tezos_protocol_environment.Internal_for_tests.Environment_protocol_T_test
       .Mock_all_unit
       .Mempool
       .Validation_error
         [Test_prevalidation.Branch_refused_error])
end

module Branch_delayed : Add_operation_result = struct
  let return _t =
    Error
      (Tezos_protocol_environment.Internal_for_tests.Environment_protocol_T_test
       .Mock_all_unit
       .Mempool
       .Validation_error
         [Test_prevalidation.Branch_delayed_error])
end

module Refused : Add_operation_result = struct
  let return _t =
    Error
      (Tezos_protocol_environment.Internal_for_tests.Environment_protocol_T_test
       .Mock_all_unit
       .Mempool
       .Validation_error
         [Test_prevalidation.Refused_error])
end

module Protocol (M : Add_operation_result) :
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
      Lwt_syntax.return (M.return t)
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

let create_prevalidator ~add_operation_result chain_db =
  let limits = Shell_limits.default_limits.prevalidator_limits in
  Prevalidator.create
    limits
    (match add_operation_result with
    | `Validated -> (module MakeFilter (Protocol (Added)))
    | `Unchanged -> (module MakeFilter (Protocol (Unchanged)))
    | `Refused -> (module MakeFilter (Protocol (Refused))))
    chain_db

let pp_expected_injection fmt = function
  | `Refused -> Format.fprintf fmt "refused"
  | `Branch_delayed -> Format.fprintf fmt "branch_delayed"
  | `Branch_refused -> Format.fprintf fmt "branch_refused"
  | `Unchanged -> Format.fprintf fmt "unchanged"
  | `Validated -> Format.fprintf fmt "validated"

let pp_expected_in_mempool fmt = function
  | `Known_valid ->
      Format.fprintf fmt "be in the known_valid mempool set of operations"
  | `Pending -> Format.fprintf fmt "be in the pending mempool set of operations"
  | `Drop -> Format.fprintf fmt "not be in the mempool sets of operations"

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
  let op = Operation.{shell = {branch}; proto} in
  let hash = Operation.hash op in
  (op, hash)

let expected_operation_db_length = function
  | `Refused -> 0
  | `Validated | `Unchanged | `Branch_delayed | `Branch_refused -> 1

let expected_mempool_from_injection_result = function
  | `Refused -> `Drop
  | `Validated -> `Known_valid
  | `Unchanged | `Branch_delayed | `Branch_refused -> `Pending

let check_operation_mempool chain_db oph expected =
  let open Lwt_syntax in
  let chain_store = Distributed_db.chain_store chain_db in
  let+ mempool = Store.Chain.mempool chain_store in
  let mempool_expected = expected_mempool_from_injection_result expected in
  let res =
    match mempool_expected with
    | `Known_valid -> Operation_hash.Set.mem oph mempool.known_valid
    | `Pending -> Operation_hash.Set.mem oph mempool.pending
    | `Drop ->
        not
          (Operation_hash.Set.mem oph mempool.known_valid
          || Operation_hash.Set.mem oph mempool.pending)
  in
  if not res then
    Test.fail
      "Operation %a (injected with %a expected result) was expected to %a"
      Operation_hash.pp
      oph
      pp_expected_injection
      expected
      pp_expected_in_mempool
      mempool_expected

let create_scenario ~injection_result ?flush_result () =
  let open Lwt_result_syntax in
  let* chain_db = create_chain_db () in
  let* prevalidator =
    create_prevalidator ~add_operation_result:injection_result chain_db
  in
  (* DDB is empty at initialization *)
  check_operation_db_length chain_db 0 ;
  let op, oph = create_dummy_operation () in
  let* () = Prevalidator.inject_operation prevalidator ~force:true op in
  check_operation_db_length
    chain_db
    (expected_operation_db_length injection_result) ;
  let*! () = Prevalidator.shutdown prevalidator in
  check_operation_db_length
    chain_db
    (expected_operation_db_length injection_result) ;
  let*! () = check_operation_mempool chain_db oph injection_result in

  match flush_result with
  | None -> return_unit
  | Some flush_result ->
      let* prevalidator =
        create_prevalidator ~add_operation_result:flush_result chain_db
      in
      let branch = Shell_test_helpers.genesis_block_hash in
      let* () =
        Prevalidator.flush
          prevalidator
          Chain_validator_worker_state.Head_increment
          branch
          (Block_hash.Set.singleton branch)
          Operation_hash.Set.empty
      in
      check_operation_db_length
        chain_db
        (expected_operation_db_length flush_result) ;
      return_unit

let () =
  ( register_test
      ~title:"Refused scenario"
      ~additional_tags:["ddb"; "table"; "handle"]
  @@ fun () -> create_scenario ~injection_result:`Refused () ) ;
  register_test
    ~title:"Validated scenario"
    ~additional_tags:["ddb"; "table"; "handle"]
  @@ fun () ->
  create_scenario ~injection_result:`Validated ~flush_result:`Refused ()
