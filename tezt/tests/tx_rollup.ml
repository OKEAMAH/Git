(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2022 Nomadic Labs <contact@nomadic-labs.com>                *)
(* Copyright (c) 2022 Marigold, <contact@marigold.dev>                       *)
(* Copyright (c) 2022 Oxhead Alpha <info@oxhead-alpha.com>                   *)
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

(* Testing
   -------
   Component:    Transactional rollups
   Invocation:   dune exec tezt/tests/main.exe -- --file tx_rollup.ml
   Subject:      .
*)

(** To be attached to process whose output needs to be captured by the
    regression framework. *)
let hooks = Tezos_regression.hooks

module Rollup = Rollup.Tx_rollup
module Parameters = Rollup.Parameters

type t = {node : Node.t; client : Client.t; rollup : string}

let init_with_tx_rollup ?additional_bootstrap_account_count
    ?(parameters = Parameters.default) ~protocol () =
  let* parameter_file = Parameters.parameter_file ~parameters protocol in
  let* (node, client) =
    Client.init_with_protocol
      ?additional_bootstrap_account_count
      ~parameter_file
      `Client
      ~protocol
      ()
  in
  (* We originate a dumb rollup to be able to generate a paths for
     tx_rollups related RPCs. *)
  let*! rollup =
    Client.Tx_rollup.originate
      ~hooks
      ~src:Constant.bootstrap1.public_key_hash
      client
  in
  let* () = Client.bake_for client in
  let* _ = Node.wait_for_level node 2 in
  return {node; client; rollup}

let submit_batch ~batch {rollup; client; node} =
  let*! () =
    Client.Tx_rollup.submit_batch
      ~hooks
      ~content:batch
      ~rollup
      ~src:Constant.bootstrap1.public_key_hash
      client
  in
  let current_level = Node.get_level node in
  let* () = Client.bake_for client in
  let* _ = Node.wait_for_level node (current_level + 1) in
  return ()

let submit_commitment ~level ~roots ~inbox_content ~predecessor
    {rollup; client; node} =
  let* inbox_merkle_root =
    match inbox_content with
    | `Root inbox_merkle_root -> inbox_merkle_root
    | `Content messages ->
        let* inbox = Rollup.compute_inbox_from_messages messages client in
        return inbox.merkle_root
  in
  let*! () =
    Client.Tx_rollup.submit_commitment
      ~hooks
      ~level
      ~roots
      ~inbox_merkle_root
      ~predecessor
      ~rollup
      ~src:Constant.bootstrap1.public_key_hash
      client
  in
  let current_level = Node.get_level node in
  let* () = Client.bake_for client in
  let* _ = Node.wait_for_level node (current_level + 1) in
  return ()

let submit_finalize_commitment ?(src = Constant.bootstrap1.public_key_hash)
    {rollup; client; node = _} =
  Client.Tx_rollup.submit_finalize_commitment ~hooks ~rollup ~src client

let submit_remove_commitment ?(src = Constant.bootstrap1.public_key_hash)
    {rollup; client; node = _} =
  Client.Tx_rollup.submit_remove_commitment ~hooks ~rollup ~src client

let submit_rejection ?(src = Constant.bootstrap1.public_key_hash) ~level
    ~message ~position ~proof {rollup; client; node = _} ~context_hash
    ~withdraw_list_hash =
  Client.Tx_rollup.submit_rejection
    ~hooks
    ~level
    ~message
    ~position
    ~proof
    ~rollup
    ~src
    ~context_hash
    ~withdraw_list_hash
    client

(* This module only registers regressions tests. Those regressions
   tests should be used to ensure there is no regressions with the
   various RPCs exported by the tx_rollups. *)
module Regressions = struct
  module RPC = struct
    let rpc_state =
      Protocol.register_regression_test
        ~__FILE__
        ~output_file:(fun _ -> "tx_rollup_rpc_state")
        ~title:"RPC (tx_rollup, regression) - state"
        ~tags:["tx_rollup"; "rpc"]
      @@ fun protocol ->
      let* {node = _; client; rollup} = init_with_tx_rollup ~protocol () in
      let*! _state = Rollup.get_state ~hooks ~rollup client in
      return ()

    let rpc_inbox =
      Protocol.register_regression_test
        ~__FILE__
        ~output_file:(fun _ -> "tx_rollup_rpc_inbox")
        ~title:"RPC (tx_rollups, regression) - inbox"
        ~tags:["tx_rollup"; "rpc"; "inbox"]
      @@ fun protocol ->
      let* ({rollup; client; node = _} as state) =
        init_with_tx_rollup ~protocol ()
      in
      (* The content of the batch does not matter for the regression test. *)
      let batch = "blob" in
      let* () = submit_batch ~batch state in
      let*! _inbox = Rollup.get_inbox ~hooks ~rollup ~level:0 client in
      unit

    let rpc_inbox_message_hash =
      Protocol.register_regression_test
        ~__FILE__
        ~output_file:(fun _ -> "tx_rollup_rpc_inbox_message_hash")
        ~title:"RPC (tx_rollups, regression) - inbox message hash"
        ~tags:["tx_rollup"; "rpc"; "inbox"; "message"]
      @@ fun protocol ->
      let* (_node, client) = Client.init_with_protocol `Client ~protocol () in
      let message = `Batch "blob" in
      let*! _hash = Rollup.message_hash ~hooks ~message client in
      unit

    let rpc_inbox_merkle_tree_hash =
      Protocol.register_regression_test
        ~__FILE__
        ~output_file:(fun _ -> "tx_rollup_rpc_inbox_merkle_tree_hash")
        ~title:"RPC (tx_rollups, regression) - inbox merkle tree hash"
        ~tags:["tx_rollup"; "rpc"; "inbox"; "merkle_tree_hash"]
      @@ fun protocol ->
      let* (_node, client) = Client.init_with_protocol `Client ~protocol () in
      let messages = [`Batch "blob"; `Batch "gloubiboulga"] in
      let* message_hashes =
        Lwt_list.map_p
          (fun message ->
            let*! message_hash = Rollup.message_hash ~hooks ~message client in
            return message_hash)
          messages
      in
      let*! _hash =
        Rollup.inbox_merkle_tree_hash ~hooks ~message_hashes client
      in
      unit

    let rpc_inbox_merkle_tree_path =
      Protocol.register_regression_test
        ~__FILE__
        ~output_file:(fun _ -> "tx_rollup_rpc_inbox_merkle_tree_path")
        ~title:"RPC (tx_rollups, regression) - inbox merkle tree path"
        ~tags:["tx_rollup"; "rpc"; "inbox"; "merkle_tree_path"]
      @@ fun protocol ->
      let* (_node, client) = Client.init_with_protocol `Client ~protocol () in
      let messages =
        [
          `Batch "Kouroukoukou";
          `Batch "roukoukou";
          `Batch "stach";
          `Batch "stach";
        ]
      in
      let* message_hashes =
        Lwt_list.map_p
          (fun message ->
            let*! message_hash = Rollup.message_hash ~hooks ~message client in
            return message_hash)
          messages
      in
      let*! _ =
        Rollup.inbox_merkle_tree_path ~hooks ~message_hashes ~position:3 client
      in
      let*! _ =
        Rollup.inbox_merkle_tree_path ~hooks ~message_hashes ~position:0 client
      in
      let*? process =
        Rollup.inbox_merkle_tree_path ~hooks ~message_hashes ~position:4 client
      in
      Process.check_error ~msg:(rex "Merkle_list_invalid_positio") process

    let rpc_commitment =
      Protocol.register_regression_test
        ~__FILE__
        ~output_file:(fun _ -> "tx_rollup_rpc_commitment")
        ~title:"RPC (tx_rollups, regression) - commitment"
        ~tags:["tx_rollup"; "rpc"; "commitment"]
      @@ fun protocol ->
      let* ({rollup; client; node = _} as state) =
        init_with_tx_rollup ~protocol ()
      in
      (* The content of the batch does not matter for the regression test. *)
      let batch = "blob" in
      let* () = submit_batch ~batch state in
      let* () = Client.bake_for client in
      let inbox_content = `Content [`Batch batch] in
      let* () =
        submit_commitment
          ~level:0
          ~roots:[Constant.tx_rollup_initial_message_result]
          ~inbox_content
          ~predecessor:None
          state
      in
      let*! _commitment =
        Rollup.get_commitment ~hooks ~block:"head" ~level:0 ~rollup client
      in
      unit

    let rpc_pending_bonded_commitment =
      Protocol.register_regression_test
        ~__FILE__
        ~output_file:(fun _ -> "tx_rollup_rpc_pending_bonded_commitments")
        ~title:"RPC (tx_rollups, regression) - pending bonded commitments"
        ~tags:["tx_rollup"; "rpc"; "commitment"; "bond"]
      @@ fun protocol ->
      let* ({rollup; client; node = _} as state) =
        init_with_tx_rollup ~protocol ()
      in
      (* The content of the batch does not matter for the regression test. *)
      let batch = "blob" in
      let* () = submit_batch ~batch state in
      let* () = Client.bake_for client in
      let inbox_content = `Content [`Batch batch] in
      let* () =
        submit_commitment
          ~level:0
          ~roots:[Constant.tx_rollup_initial_message_result]
          ~inbox_content
          ~predecessor:None
          state
      in
      let*! _commitment =
        Rollup.get_pending_bonded_commitments
          ~hooks
          ~block:"head"
          ~rollup
          ~pkh:Constant.bootstrap1.public_key_hash
          client
      in
      (* Use a key which has no commitment. *)
      let*! _commitment =
        Rollup.get_pending_bonded_commitments
          ~hooks
          ~block:"head"
          ~rollup
          ~pkh:Constant.bootstrap2.public_key_hash
          client
      in
      unit

    let batch_encoding =
      Protocol.register_regression_test
        ~__FILE__
        ~output_file:(fun _ -> "tx_rollup_batch_encoding")
        ~title:"RPC (tx_rollups, regression) - batch encoding"
        ~tags:["tx_rollup"; "batch"; "encoding"]
      @@ fun protocol ->
      let* ({client; rollup = _; node = _} as state) =
        init_with_tx_rollup ~protocol ()
      in
      (* Batch with all possible characters. *)
      let batch = String.init 256 Char.chr in
      let* () = submit_batch ~batch state in
      let* block = RPC.get_block ~block:"head" client in
      let op = JSON.(block |-> "operations" |=> 3 |=> 0 |-> "contents" |=> 0) in
      Check.(
        ((JSON.(op |-> "kind" |> as_string) = "tx_rollup_submit_batch")
           ~error_msg:"Unexpected operation. Got: %L. Expected: %R.")
          string) ;
      let batch_content = JSON.(op |-> "content") in
      let batch_content_str = JSON.encode batch_content in
      Regression.capture batch_content_str ;
      if not (JSON.is_string batch_content) then
        Test.fail
          ~__LOC__
          "Batch content in JSON should be a string: %s."
          batch_content_str ;
      unit
  end

  module Limits = struct
    (* The constant comes from the default parameters of the protocol. *)
    let batch_limit = 5_000

    let inbox_limit = 100_000

    let submit_empty_batch =
      Protocol.register_regression_test
        ~__FILE__
        ~output_file:(fun _ -> "tx_rollup_limit_empty_batch")
        ~title:"Submit empty batch"
        ~tags:["tx_rollup"; "batch"; "client"]
      @@ fun protocol ->
      let* state = init_with_tx_rollup ~protocol () in
      let batch = "" in
      let*? process =
        Client.Tx_rollup.submit_batch
          ~hooks
          ~content:batch
          ~rollup:state.rollup
          ~src:Constant.bootstrap1.public_key_hash
          state.client
      in
      Process.check_error
        ~msg:
          (rex
             "A message submitted to a transaction rollup inbox exceeds limit")
        process

    let submit_maximum_size_batch =
      Protocol.register_regression_test
        ~__FILE__
        ~output_file:(fun _ -> "tx_rollup_limit_maximum_size_batch")
        ~title:"Submit maximum size batch"
        ~tags:["tx_rollup"; "batch"; "client"]
      @@ fun protocol ->
      let* state = init_with_tx_rollup ~protocol () in
      let batch = String.make batch_limit 'b' in
      let* () = submit_batch ~batch state in
      let batch = String.make (batch_limit + 1) 'c' in
      let*? process =
        Client.Tx_rollup.submit_batch
          ~hooks
          ~content:batch
          ~rollup:state.rollup
          ~src:Constant.bootstrap1.public_key_hash
          state.client
      in
      Process.check_error
        ~msg:
          (rex
             "A message submitted to a transaction rollup inbox exceeds limit")
        process

    let inbox_maximum_size =
      Protocol.register_regression_test
        ~__FILE__
        ~output_file:(fun _ -> "tx_rollup_limit_maximum_size_inbox")
        ~title:"Submit maximum size inbox"
        ~tags:["tx_rollup"; "inbox"; "client"]
      @@ fun protocol ->
      (* The test assumes inbox_limit % batch_limit = 0 *)
      let max_batch_number_per_inbox = inbox_limit / batch_limit in
      let additional_bootstrap_account_count = max_batch_number_per_inbox - 5 in
      let* {client; rollup; node} =
        init_with_tx_rollup ~additional_bootstrap_account_count ~protocol ()
      in
      let batch = String.make batch_limit 'a' in
      let* () =
        fold max_batch_number_per_inbox () (fun i () ->
            let src = Account.bootstrap (i + 1) in
            let*! () =
              Client.Tx_rollup.submit_batch
                ~hooks
                ~content:batch
                ~rollup
                ~src
                client
            in
            unit)
      in
      let current_level = Node.get_level node in
      let* () = Client.bake_for client in
      let* _ = Node.wait_for_level node (current_level + 1) in
      let*! {inbox_length = _; cumulated_size; merkle_root = _} =
        Rollup.get_inbox ~hooks ~rollup ~level:0 client
      in
      Check.(cumulated_size = inbox_limit)
        Check.int
        ~error_msg:"Unexpected inbox size. Expected %R. Got %L" ;
      unit
  end

  module Fail = struct
    let client_submit_batch_invalid_rollup_address =
      let open Tezt_tezos in
      Protocol.register_regression_test
        ~__FILE__
        ~output_file:(fun _ ->
          "tx_rollup_client_submit_batch_invalid_rollup_address")
        ~title:"Submit a batch to an invalid rollup address should fail"
        ~tags:["tx_rollup"; "client"; "fail"; "batch"]
      @@ fun protocol ->
      let* parameter_file = Parameters.parameter_file protocol in
      let* (_node, client) =
        Client.init_with_protocol ~parameter_file `Client ~protocol ()
      in
      let invalid_address = "this is an invalid tx rollup address" in
      let*? process =
        Client.Tx_rollup.submit_batch
          ~hooks
          ~content:""
          ~rollup:invalid_address
          ~src:Constant.bootstrap1.public_key_hash
          client
      in

      let* () =
        Process.check_error
          ~exit_code:1
          ~msg:
            (rex
               ("Parameter '" ^ invalid_address
              ^ "' is an invalid tx rollup address"))
          process
      in
      unit

    let client_submit_finalize_commitment_no_batch =
      Protocol.register_regression_test
        ~__FILE__
        ~output_file:(fun _ -> "tx_rollup_finalize_commitment_no_batch")
        ~title:"Submit a finalize commitment operation without batch"
        ~tags:["tx_rollup"; "client"; "fail"; "finalize"]
      @@ fun protocol ->
      let* ({rollup = _; client; node = _} as state) =
        init_with_tx_rollup ~protocol ()
      in
      let* () = Client.bake_for client in
      let*? process = submit_finalize_commitment state in
      Process.check_error
        ~exit_code:1
        ~msg:(rex "proto.alpha.tx_rollup_no_commitment_to_finalize")
        process

    let client_submit_finalize_commitment_no_commitment =
      Protocol.register_regression_test
        ~__FILE__
        ~output_file:(fun _ -> "tx_rollup_finalize_commitment_no_commitment")
        ~title:"Submit a finalize commitment operation without commitment"
        ~tags:["tx_rollup"; "client"; "fail"; "finalize"]
      @@ fun protocol ->
      let* ({rollup = _; client; node = _} as state) =
        init_with_tx_rollup ~protocol ()
      in
      (* The content of the batch does not matter for the regression test. *)
      let batch = "blob" in
      let* () = submit_batch ~batch state in
      let* () = Client.bake_for client in
      let*? process = submit_finalize_commitment state in
      Process.check_error
        ~exit_code:1
        ~msg:(rex "proto.alpha.tx_rollup_no_commitment_to_finalize")
        process

    let client_submit_finalize_commitment_future =
      Protocol.register_regression_test
        ~__FILE__
        ~output_file:(fun _ -> "tx_rollup_finalize_commitment_future")
        ~title:
          "Submit a finalize commitment operation for a commitment in the \
           future"
        ~tags:["tx_rollup"; "client"; "fail"; "finalize"]
      @@ fun protocol ->
      let* ({rollup = _; client; node = _} as state) =
        init_with_tx_rollup ~protocol ()
      in
      (* The content of the batch does not matter for the regression test. *)
      let batch = "blob" in
      let* () = submit_batch ~batch state in
      let* () = Client.bake_for client in
      let*? process = submit_finalize_commitment state in
      Process.check_error
        ~exit_code:1
        ~msg:(rex "proto.alpha.tx_rollup_no_commitment_to_finalize")
        process

    let client_submit_finalize_too_recent_commitment =
      Protocol.register_regression_test
        ~__FILE__
        ~output_file:(fun _ -> "tx_rollup_finalize_too_recent_commitment")
        ~title:"Try to finalize a too recent commitment"
        ~tags:["tx_rollup"; "client"; "fail"; "finalize"]
      @@ fun protocol ->
      let* ({rollup = _; client; node = _} as state) =
        init_with_tx_rollup ~protocol ()
      in
      (* The content of the batch does not matter for the regression test. *)
      let batch = "blob" in
      let* () = submit_batch ~batch state in
      let* () = Client.bake_for client in
      let inbox_content = `Content [`Batch batch] in
      let* () =
        submit_commitment
          ~level:0
          ~roots:[Constant.tx_rollup_initial_message_result]
          ~inbox_content
          ~predecessor:None
          state
      in
      let* () = Client.bake_for client in
      let*? process = submit_finalize_commitment state in
      Process.check_error
        ~exit_code:1
        ~msg:(rex "proto.alpha.tx_rollup_no_commitment_to_finalize")
        process
  end

  let register protocols =
    RPC.rpc_state protocols ;
    RPC.rpc_inbox protocols ;
    RPC.rpc_inbox_message_hash protocols ;
    RPC.rpc_inbox_merkle_tree_hash protocols ;
    RPC.rpc_inbox_merkle_tree_path protocols ;
    RPC.rpc_commitment protocols ;
    RPC.rpc_pending_bonded_commitment protocols ;
    RPC.batch_encoding protocols ;
    Limits.submit_empty_batch protocols ;
    Limits.submit_maximum_size_batch protocols ;
    Limits.inbox_maximum_size protocols ;
    Fail.client_submit_batch_invalid_rollup_address protocols ;
    Fail.client_submit_finalize_commitment_no_batch protocols ;
    Fail.client_submit_finalize_commitment_no_commitment protocols ;
    Fail.client_submit_finalize_commitment_future protocols ;
    Fail.client_submit_finalize_too_recent_commitment protocols
end

(** To be attached to process whose output needs to be captured by the
    regression framework. *)
let hooks = Tezos_regression.hooks

let submit_three_batches_and_check_size ~rollup ~tezos_level ~tx_level node
    client batches =
  let* () =
    Lwt_list.iter_s
      (fun (content, src, _) ->
        let*! () =
          Client.Tx_rollup.submit_batch ~hooks ~content ~rollup ~src client
        in
        unit)
      batches
  in
  let* () = Client.bake_for client in
  let* _ = Node.wait_for_level node tezos_level in
  (* Check the inbox has been created, with the expected cumulated size. *)
  let messages = List.map (fun (contents, _, _) -> `Batch contents) batches in
  let* expected_inbox =
    Rollup.compute_inbox_from_messages ~hooks messages client
  in
  let*! inbox = Rollup.get_inbox ~hooks ~rollup ~level:tx_level client in
  Check.(
    ((inbox = expected_inbox)
       ~error_msg:"Unexpected inbox. Got: %L. Expected: %R.")
      Rollup.Check.inbox) ;
  return ()

let test_submit_batches_in_several_blocks =
  Protocol.register_test
    ~__FILE__
    ~title:"Submit batches in several blocks"
    ~tags:["tx_rollup"]
  @@ fun protocol ->
  let* parameter_file = Parameters.parameter_file protocol in
  let* (node, client) =
    Client.init_with_protocol ~parameter_file `Client ~protocol ()
  in
  let*! rollup =
    Client.Tx_rollup.originate
      ~hooks
      ~src:Constant.bootstrap1.public_key_hash
      client
  in
  let* () = Client.bake_for client in
  let* _ = Node.wait_for_level node 2 in
  (* We check the rollup exists by trying to fetch its state. Since it
     is a regression test, we can detect changes to this default
     state. *)
  let*! state = Rollup.get_state ~hooks ~rollup client in
  let expected_state =
    Rollup.
      {
        oldest_inbox_level = None;
        head_level = None;
        commitment_head_level = None;
        burn_per_byte = 0;
        inbox_ema = 0;
      }
  in
  Check.(state = expected_state)
    Rollup.Check.state
    ~error_msg:"Unexpected state. Got: %L. Expected: %R." ;
  let batch = "tezos" in
  let*! () =
    Client.Tx_rollup.submit_batch
      ~hooks
      ~content:batch
      ~rollup
      ~src:Constant.bootstrap1.public_key_hash
      client
  in
  let batch1 = "tezos" in
  let batch2 = "tx_rollup" in
  let batch3 = "layer-2" in
  let*! (`Hash batch1_hash) =
    Rollup.message_hash ~message:(`Batch batch1) client
  in
  let*! (`Hash batch2_hash) =
    Rollup.message_hash ~message:(`Batch batch2) client
  in
  let*! (`Hash batch3_hash) =
    Rollup.message_hash ~message:(`Batch batch3) client
  in
  let submission =
    [
      (batch2, Constant.bootstrap2.public_key_hash, batch2_hash);
      (batch3, Constant.bootstrap3.public_key_hash, batch3_hash);
      (batch1, Constant.bootstrap1.public_key_hash, batch1_hash);
    ]
  in
  (* Let’s try once and see if everything goes as expected *)
  let* () =
    submit_three_batches_and_check_size
      ~rollup
      node
      client
      submission
      ~tezos_level:3
      ~tx_level:0
  in
  (* Let’s try to see if we can submit three more batches in the next level *)
  let* () =
    submit_three_batches_and_check_size
      ~rollup
      node
      client
      submission
      ~tezos_level:4
      ~tx_level:1
  in
  let* () =
    submit_three_batches_and_check_size
      ~rollup
      node
      client
      submission
      ~tezos_level:5
      ~tx_level:2
  in
  unit

let test_submit_from_originated_source =
  let open Tezt_tezos in
  Protocol.register_test
    ~__FILE__
    ~title:"Submit from an originated contract should fail"
    ~tags:["tx_rollup"; "client"]
  @@ fun protocol ->
  let* parameter_file = Parameters.parameter_file protocol in
  let* (node, client) =
    Client.init_with_protocol ~parameter_file `Client ~protocol ()
  in
  (* We begin by originating a contract *)
  let* originated_contract =
    Client.originate_contract
      ~alias:"originated_contract_simple"
      ~amount:Tez.zero
      ~src:"bootstrap1"
      ~prg:"file:./tezt/tests/contracts/proto_alpha/str_id.tz"
      ~init:"Some \"initial storage\""
      ~burn_cap:Tez.(of_int 3)
      client
  in
  let* () = Client.bake_for client in
  let* _ = Node.wait_for_level node 2 in
  (* We originate a tx_rollup using an implicit account *)
  let*! rollup =
    Client.Tx_rollup.originate ~src:Constant.bootstrap1.public_key_hash client
  in
  let* () = Client.bake_for client in
  let batch = "tezos" in
  (* Finally, we submit a batch to the tx_rollup from an originated contract *)
  let*? process =
    Client.Tx_rollup.submit_batch
      ~hooks
      ~content:batch
      ~rollup
      ~src:originated_contract
      client
  in
  let* () =
    Process.check_error
      ~exit_code:1
      ~msg:(rex "Only implicit accounts can submit transaction rollup batches")
      process
  in
  unit

let test_rollup_with_two_commitments =
  Protocol.register_test
    ~__FILE__
    ~title:"Submit 2 batches, commit, finalize and remove the commitments"
    ~tags:["tx_rollup"; "commitment"; "batch"]
  @@ fun protocol ->
  let parameters = Parameters.{finality_period = 1; withdraw_period = 1} in
  let* ({rollup; client; node = _} as state) =
    init_with_tx_rollup ~parameters ~protocol ()
  in
  let batch = "blob" in
  let* () = submit_batch ~batch state in
  let* () = Client.bake_for client in
  let inbox_content = `Content [`Batch batch] in
  let* () =
    submit_commitment
      ~level:0
      ~roots:[Constant.tx_rollup_initial_message_result]
      ~inbox_content
      ~predecessor:None
      state
  in
  let* () =
    repeat parameters.finality_period (fun () -> Client.bake_for client)
  in
  let*! () = submit_finalize_commitment state in
  (* A second submission just to ensure it can be included into a
     block even if it fails. *)
  let*! () =
    submit_finalize_commitment ~src:Constant.bootstrap2.public_key_hash state
  in
  let* _ = Client.bake_for client in
  let*? process = Rollup.get_inbox ~hooks ~rollup ~level:0 client in
  let* () =
    Process.check_error ~msg:(rex " No service found at this URL") process
  in
  let* json = RPC.get_operations client in
  let manager_operations = JSON.(json |=> 3 |> as_list) in
  Check.(List.length manager_operations = 2)
    Check.int
    ~error_msg:"Two operations manager expected in the last block" ;
  let first_op = List.nth manager_operations 0 in
  let second_op = List.nth manager_operations 1 in
  let get_status op =
    JSON.(
      op |-> "contents" |=> 0 |-> "metadata" |-> "operation_result" |-> "status"
      |> as_string)
  in
  let first_op_status = get_status first_op in
  let second_op_status = get_status second_op in
  Check.(first_op_status = "applied")
    Check.string
    ~error_msg:"The first operation status expected is %R. Got %L" ;
  Check.(second_op_status = "failed")
    Check.string
    ~error_msg:"The second operation status expected is %R. Got %L" ;
  (* We try to finalize a new commitment but it fails. *)
  let*? process = submit_finalize_commitment state in
  let* () =
    Process.check_error
      ~exit_code:1
      ~msg:(rex "proto.alpha.tx_rollup_no_commitment_to_finalize")
      process
  in
  let batch = "blob" in
  let* () = submit_batch ~batch state in
  let* () = Client.bake_for client in
  let*! commitment = Rollup.get_commitment ~hooks ~rollup ~level:0 client in
  let* () = Client.bake_for client in
  let*! () =
    submit_remove_commitment ~src:Constant.bootstrap2.public_key_hash state
  in
  let* () = Client.bake_for client in
  let predecessor = Some JSON.(commitment |-> "commitment_hash" |> as_string) in
  let inbox_content = `Content [`Batch batch] in
  let* () =
    submit_commitment
      ~level:1
      ~roots:[Constant.tx_rollup_initial_message_result]
      ~inbox_content
      ~predecessor
      state
  in
  let* () =
    repeat parameters.finality_period (fun () -> Client.bake_for client)
  in
  let*! () =
    submit_finalize_commitment ~src:Constant.bootstrap2.public_key_hash state
  in
  let*! _inbox = Rollup.get_inbox ~hooks ~rollup ~level:1 client in
  let* () = Client.bake_for client in
  let*? process = Rollup.get_inbox ~hooks ~rollup ~level:0 client in
  let* () =
    Process.check_error ~msg:(rex " No service found at this URL") process
  in
  let*! _commitment = Rollup.get_commitment ~hooks ~rollup ~level:0 client in
  let* () = Client.bake_for client in
  let*! () =
    submit_remove_commitment ~src:Constant.bootstrap2.public_key_hash state
  in
  let* () = Client.bake_for client in
  let*! _commitment = Rollup.get_commitment ~hooks ~rollup ~level:0 client in
  let*! _commitment = Rollup.get_commitment ~hooks ~rollup ~level:1 client in
  unit

let test_rollup_last_commitment_is_rejected =
  Protocol.register_test
    ~__FILE__
    ~title:"reject last commitment"
    ~tags:["tx_rollup"; "rejection"; "batch"]
  @@ fun protocol ->
  let parameters = Parameters.{finality_period = 1; withdraw_period = 1} in
  let* ({rollup; client; node = _} as state) =
    init_with_tx_rollup ~parameters ~protocol ()
  in
  let batch = "blob" in
  let* () = submit_batch ~batch state in
  let* () = Client.bake_for client in
  let inbox_content = `Content [`Batch batch] in
  let* () =
    submit_commitment
      ~level:0
      ~roots:[Constant.tx_rollup_initial_message_result]
      ~inbox_content
      ~predecessor:None
      state
  in
  let* () =
    repeat parameters.finality_period (fun () -> Client.bake_for client)
  in
  let*! _ = RPC.Tx_rollup.get_state ~rollup client in
  let*! message_hash = Rollup.message_hash ~message:(`Batch "blob") client in
  let*! path =
    Rollup.inbox_merkle_tree_path
      ~message_hashes:[message_hash]
      ~position:0
      client
  in
  (* This is the encoding of [batch]. *)
  let message = "{ \"batch\": \"blob\"}" in
  let*! () =
    submit_rejection
      ~level:0
      ~message
      ~position:0
      ~path:(path |> JSON.encode)
      ~proof:true
      ~context_hash:Constant.tx_rollup_empty_l2_context
      ~withdraw_list_hash:Constant.tx_rollup_empty_withdraw_list
      state
  in
  let* () = Client.bake_for client in
  let*! _ = RPC.Tx_rollup.get_state ~rollup client in
  let* _ = RPC.get_block client in
  unit

let test_rollup_wrong_rejection =
  Protocol.register_test
    ~__FILE__
    ~title:"wrong rejection"
    ~tags:["tx_rollup"; "rejection"; "batch"]
  @@ fun protocol ->
  let parameters = Parameters.{finality_period = 1; withdraw_period = 1} in
  let* ({rollup; client; node = _} as state) =
    init_with_tx_rollup ~parameters ~protocol ()
  in
  let batch = "blob" in
  let* () = submit_batch ~batch state in
  let* () = Client.bake_for client in
  let inbox_content = `Content [`Batch batch] in
  let* () =
    submit_commitment
      ~level:0
      ~roots:[Constant.tx_rollup_initial_message_result]
      ~inbox_content
      ~predecessor:None
      state
  in
  let* () =
    repeat parameters.finality_period (fun () -> Client.bake_for client)
  in
  (* This is the encoding of [batch]. *)
  let message = `Batch batch in
  let*! _ = RPC.Tx_rollup.get_state ~rollup client in
  let*! message_hash = Rollup.message_hash ~message:(`Batch "blob") client in
  let*! path =
    Rollup.inbox_merkle_tree_path
      ~message_hashes:[message_hash]
      ~position:0
      client
  in
  let message_path = List.map (fun x -> JSON.as_string x) (JSON.as_list path) in
  let* (`OpHash _op) =
    Operation.inject_rejection
      ~source:Constant.bootstrap1
      ~tx_rollup:state.rollup
      ~proof:false
      ~level:0
      ~message
      ~message_position:0
      ~message_path
      ~previous_message_result:
        ( Constant.tx_rollup_empty_l2_context,
          Constant.tx_rollup_empty_withdraw_list )
      state.client
  in
  let* () = Client.bake_for client in
  let*! state = Rollup.get_state ~rollup client in
  let* json = RPC.get_block client in
  let operation_result =
    JSON.(
      json |-> "operations" |=> 3 |=> 0 |-> "contents" |=> 0 |-> "metadata"
      |-> "operation_result")
  in
  let status = JSON.(operation_result |-> "status" |> as_string) in
  Check.(status = "failed")
    Check.string
    ~error_msg:"Expected status: %R. Got %L" ;
  let error_id =
    JSON.(operation_result |-> "errors" |=> 0 |-> "id" |> as_string)
  in
  Check.(error_id = "proto.alpha.tx_rollup_invalid_proof")
    Check.string
    ~error_msg:"Expected error id: %R. Got %L" ;
  match state.commitment_head_level with
  | Some (0, _) -> unit
  | None | Some _ ->
      Test.fail "Wrong rollup state: Expected commitment head at level 0"

let register ~protocols =
  Regressions.register protocols ;
  test_submit_batches_in_several_blocks protocols ;
  test_submit_from_originated_source protocols ;
  test_rollup_with_two_commitments protocols ;
  test_rollup_last_commitment_is_rejected protocols ;
  test_rollup_wrong_rejection protocols
