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
let originate_contract ~fee ~b source =
  let open Lwt_result_syntax in
  let contract =
    Contract_helpers.load_script
      ~storage:"0"
      "./src/proto_alpha/lib_protocol/test/integration/michelson/contracts/rec_fact.tz"
  in
  let* op, c = Op.contract_origination (B b) ~fee ~script:contract source in
  let* b = Block.bake b ~operation:op in
  return (b, c)

let check_storage ~contract ~b ~expected =
  let open Lwt_result_syntax in
  let hash =
    match contract with Contract.Originated hash -> hash | _ -> assert false
  in
  let* b = Context.Contract.storage (B b) hash in
  let prim =
    let open Op.Micheline in
    strip_locations (Int ((), Z.of_int expected))
  in
  Assert.equal_with_encoding ~loc:__LOC__ Script.expr_encoding b prim

let param number =
  let open Op.Micheline in
  Script.lazy_expr @@ strip_locations (Int ((), Z.of_int number))

let test_singlesource_batch_with_host_op () =
  let open Lwt_result_syntax in
  let* b, (host, guest) =
    Context.init2 ~consensus_threshold:0 ~sponsored_operations_enable:true ()
  in
  let fee = Test_tez.of_int 10 in
  let* b, contract = originate_contract ~fee ~b host in
  let* op1 =
    Op.transaction (B b) ~parameters:(param 5) ~fee guest contract Tez.zero
  in
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
  check_storage ~contract ~b ~expected:120

let test_multisource_batch_with_host_op () =
  let open Lwt_result_syntax in
  let* b, (host, guest, guest2) =
    Context.init3 ~consensus_threshold:0 ~sponsored_operations_enable:true ()
  in
  let fee = Test_tez.of_int 10 in
  let* b, contract = originate_contract ~fee ~b host in
  let* b, contract2 = originate_contract ~fee ~b host in
  let* op1 =
    Op.transaction (B b) ~parameters:(param 5) ~fee guest contract Tez.zero
  in
  let* op2 =
    Op.transaction (B b) ~parameters:(param 5) ~fee guest2 contract2 Tez.zero
  in
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
            ~guest:(Context.Contract.pkh guest2)
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
  let* host_balance = Context.Contract.balance (B b) host in
  Log.info "host balance: %a" Tez.pp host_balance ;
  let* () = check_storage ~contract ~b ~expected:120 in
  check_storage ~contract:contract2 ~b ~expected:120

let test_multisource_batch_with_host_op_or_sem () =
  let open Lwt_result_syntax in
  let* b, (host, guest, host2) =
    Context.init3 ~consensus_threshold:0 ~sponsored_operations_enable:true ()
  in
  let target = Account.new_account () in
  let fee = Tez.one in
  let* b, contract = originate_contract ~b ~fee host in
  let* op1 =
    Op.transaction (B b) ~fee host (Contract.Implicit target.pkh) Tez.one
  in
  let* b =
    Block.bake
      ~policy:(Block.Excluding [Context.Contract.pkh guest])
      b
      ~operation:op1
  in
  let* counter = Context.Contract.counter (B b) guest in
  let* op1 =
    Op.transaction
      (B b)
      ~counter
      ~parameters:(param 5)
      ~fee
      guest
      contract
      Tez.zero
  in
  let* op2 =
    Op.transaction
      (B b)
      ~counter
      ~parameters:(param 4)
      ~fee
      guest
      contract
      Tez.zero
  in
  let* b1, b2 =
    match (op1, op2) with
    | ( {
          protocol_data =
            Operation_data
              {contents = Single (Manager_operation _ as contents); _};
          _;
        },
        {
          protocol_data =
            Operation_data
              {contents = Single (Manager_operation _ as contents2); _};
          _;
        } ) -> (
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
              Op.transaction
                ~counter
                (B b)
                host2
                (Contract.Implicit target.pkh)
                ~fee
                Tez.one
            in
            let counter = Manager_counter.succ counter in
            let* hosted2 =
              Op.host
                ~counter
                (B b)
                host2
                ~guest:(Context.Contract.pkh guest)
                ~ops:(Single contents2)
            in
            let* hosted3 =
              Op.host
                ~counter:(Manager_counter.succ counter)
                (B b)
                host2
                ~guest:target.pkh
                ~ops:(Single reveal)
            in
            let* hosted2 = Op.sponsor (B b) host2 ~ops:hosted2 in
            let* hosted3 = Op.sponsor (B b) host2 ~ops:hosted3 in
            let* second =
              Op.batch_operations
                ~recompute_counters:false
                ~source:host2
                (B b)
                [hosted; hosted2; hosted3]
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
  let* () = check_storage ~b ~contract ~expected:120 in
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
