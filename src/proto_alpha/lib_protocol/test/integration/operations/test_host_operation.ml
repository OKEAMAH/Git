(*****************************************************************************)

(*                                                                           *)
(* SPDX-License-Identifier: MIT                                              *)
(* Copyright (c) 2023 Marigold, <contact@marigold.dev>                       *)
(*                                                                           *)
(*****************************************************************************)

open Protocol
open Alpha_context

(** Testing
    -------
    Component:    Host operation
    Invocation:   dune exec src/proto_alpha/lib_protocol/test/integration/michelson/main.exe \
                   -- --file test_host_operation.ml
    Subject:      Test the host manager operation.
*)

let test_multisource_batch_without_host_op_fails () =
  let open Lwt_result_syntax in
  let* b, (host, guest, target) =
    Context.init3 ~consensus_threshold:0 ~sponsored_operations_enable:true ()
  in
  let* host_balance = Context.Contract.balance (B b) host in
  Log.info "host balance: %a" Tez.pp host_balance ;
  let fee = Test_tez.of_int 10 in
  let* op1 = Op.transaction (B b) ~fee host target Test_tez.(of_int 100000) in
  let* op2 = Op.transaction (B b) ~fee guest target Test_tez.(of_int 200000) in
  let* batch =
    Op.batch_operations ~recompute_counters:true ~source:host (B b) [op1; op2]
  in
  let*! res = Block.bake ~operation:batch b in
  let* () =
    Assert.proto_error ~loc:__LOC__ res (function
        | Validate_errors.Manager.Inconsistent_sources -> true
        | _ -> false)
  in
  return_unit

let test_singlesource_batch_with_host_op () =
  let open Lwt_result_syntax in
  let* b, (host, guest, target) =
    Context.init3 ~consensus_threshold:0 ~sponsored_operations_enable:true ()
  in
  let fee = Test_tez.of_int 10 in
  let* op1 = Op.transaction (B b) ~fee guest target Test_tez.(of_int 200000) in
  let* batch =
    match op1 with
    | {
     protocol_data =
       Operation_data {contents = Single (Manager_operation _) as contents; _};
     _;
    } ->
        let* hosted =
          Op.host (B b) host ~guest:(Context.Contract.pkh guest) ~ops:contents
        in
        Op.sponsor (B b) host ~ops:hosted
    | _ -> assert false
  in
  let* b = Block.bake ~operation:batch b in
  let* i = Incremental.begin_construction b in
  let* (b : Block.t) = Incremental.finalize_block i in
  let* host_balance = Context.Contract.balance (B b) host in
  Log.info "host balance: %a" Tez.pp host_balance ;
  return_unit

let test_multisource_batch_with_host_op () =
  let open Lwt_result_syntax in
  let* b, (host, guest, target) =
    Context.init3 ~consensus_threshold:0 ~sponsored_operations_enable:true ()
  in
  let fee = Test_tez.of_int 10 in
  let* op1 = Op.transaction (B b) ~fee guest target Test_tez.(of_int 200000) in
  let* op2 = Op.transaction (B b) ~fee target guest Test_tez.(of_int 200000) in
  let* batch =
    match (op1, op2) with
    | ( {
          protocol_data =
            Operation_data
              {contents = Single (Manager_operation _) as contents; _};
          _;
        },
        {
          protocol_data =
            Operation_data
              {contents = Single (Manager_operation _) as contents2; _};
          _;
        } ) ->
        let* counter = Context.Contract.counter (B b) host in
        let* hosted =
          Op.host
            (B b)
            ~counter
            host
            ~guest:(Context.Contract.pkh guest)
            ~ops:contents
        in
        let counter = Manager_counter.succ counter in
        let* hosted2 =
          Op.host
            (B b)
            ~counter
            host
            ~guest:(Context.Contract.pkh target)
            ~ops:contents2
        in
        let ops = Operation.to_list hosted @ Operation.to_list hosted2 in
        let ops =
          Operation.of_list ops |> WithExceptions.Result.get_ok ~loc:__LOC__
        in
        Op.sponsor (B b) host ~ops
    | _ -> assert false
  in
  let* b = Block.bake ~operation:batch b in
  let* i = Incremental.begin_construction b in
  let* (b : Block.t) = Incremental.finalize_block i in
  let* host_balance = Context.Contract.balance (B b) host in
  Log.info "host balance: %a" Tez.pp host_balance ;
  return_unit

let test_multisource_batch_with_host_op_or_sem () =
  let open Lwt_result_syntax in
  let* b, (host, guest, host2) =
    Context.init3 ~consensus_threshold:0 ~sponsored_operations_enable:true ()
  in
  let target = Account.new_account () in
  let fee = Tez.one in
  let amount = Tez.(mul_exn one 100) in
  let* counter = Context.Contract.counter (B b) guest in
  let* op1 =
    Op.transaction
      ~counter
      (B b)
      ~fee
      guest
      (Contract.Implicit target.pkh)
      amount
  in
  let* b =
    Block.bake
      ~policy:(Block.Excluding [Context.Contract.pkh guest])
      b
      ~operation:op1
  in
  let* op1 =
    Op.transaction
      ~force_reveal:true
      ~counter:(Manager_counter.succ counter)
      (B b)
      ~fee
      guest
      (Contract.Implicit target.pkh)
      amount
  in
  let* guest_balance = Context.Contract.balance (B b) guest in
  let* b1, b2 =
    match op1 with
    | {
     protocol_data =
       Operation_data {contents = Single (Manager_operation _ as contents); _};
     _;
    } -> (
        let* hosted =
          Op.host
            (B b)
            host
            ~guest:(Context.Contract.pkh guest)
            ~ops:(Single contents)
        in
        let* first = Op.sponsor (B b) host ~ops:hosted in
        let* reveal_op = Op.revelation ~fee:Tez.one (B b) target.pk in
        match reveal_op with
        | {
         protocol_data =
           Operation_data {contents = Single (Manager_operation _ as reveal); _};
         _;
        } ->
            let* counter = Context.Contract.counter (B b) host2 in
            let* hosted =
              Op.host
                ~counter
                (B b)
                host2
                ~guest:(Context.Contract.pkh guest)
                ~ops:(Single contents)
            in
            let* hosted2 =
              Op.host
                ~counter:(Manager_counter.succ counter)
                (B b)
                host2
                ~guest:target.pkh
                ~ops:(Single reveal)
            in
            let* hosted = Op.sponsor (B b) host2 ~ops:hosted in
            let* hosted2 = Op.sponsor (B b) host2 ~ops:hosted2 in
            let* second =
              Op.batch_operations
                ~recompute_counters:false
                ~source:host2
                (B b)
                [hosted; hosted2]
            in
            return (first, second)
        | _ -> assert false)
    | _ -> assert false
  in
  let* b =
    Block.bake
      ~policy:(Block.Excluding [Context.Contract.pkh guest])
      ~operations:[b1; b2]
      b
  in
  let* () =
    Assert.balance_was_debited ~loc:__LOC__ (B b) guest guest_balance amount
  in
  let+ is_revealed =
    Context.Contract.is_manager_key_revealed (B b) (Implicit target.pkh)
  in
  if not is_revealed then Stdlib.failwith "New contract revelation failed."

let tests =
  [
    Tztest.tztest
      "Test single-source batch with Host manager operation succeeds"
      `Quick
      test_singlesource_batch_with_host_op;
    Tztest.tztest
      "Test multi-source batch with Host manager operation succeeds"
      `Quick
      test_multisource_batch_with_host_op;
    Tztest.tztest
      "Test multi-source batch with or semantics with Host manager operation \
       succeeds"
      `Quick
      test_multisource_batch_with_host_op_or_sem;
  ]

let () =
  Alcotest_lwt.run ~__FILE__ Protocol.name [("Host operation", tests)]
  |> Lwt_main.run
