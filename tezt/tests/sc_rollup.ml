(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2021 Nomadic Labs <contact@nomadic-labs.com>                *)
(* Copyright (c) 2022 TriliTech <contact@trili.tech>                         *)
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
   Component:    Smart Contract Optimistic Rollups
   Invocation:   dune exec tezt/tests/main.exe -- --file sc_rollup.ml
*)

open Base

let hooks = Tezos_regression.hooks

(*

   Helpers
   =======

*)

(* Number of levels needed to process a head as finalized. This value should
   be the same as `node_context.block_finality_time`, where `node_context` is
   the `Node_context.t` used by the rollup node. For Tenderbake, the
   block finality time is 2. *)
let block_finality_time = 2

type sc_rollup_constants = {
  origination_size : int;
  challenge_window_in_blocks : int;
  max_number_of_messages_per_commitment_period : int;
  stake_amount : Tez.t;
  commitment_period_in_blocks : int;
  max_lookahead_in_blocks : int32;
  max_active_outbox_levels : int32;
  max_outbox_messages_per_level : int;
  number_of_sections_in_dissection : int;
}

(** [boot_sector_of k] returns a valid boot sector for a PVM of
    kind [kind]. *)
let boot_sector_of = function
  | "arith" -> ""
  | "wasm_2_0_0" -> Constant.wasm_incomplete_kernel_boot_sector
  | kind -> raise (Invalid_argument kind)

let get_sc_rollup_constants client =
  let* json = RPC.get_constants client in
  let open JSON in
  let origination_size = json |-> "sc_rollup_origination_size" |> as_int in
  let challenge_window_in_blocks =
    json |-> "sc_rollup_challenge_window_in_blocks" |> as_int
  in
  let max_number_of_messages_per_commitment_period =
    json |-> "sc_rollup_max_number_of_messages_per_commitment_period" |> as_int
  in
  let stake_amount =
    json |-> "sc_rollup_stake_amount" |> as_string |> Int64.of_string
    |> Tez.of_mutez_int64
  in
  let commitment_period_in_blocks =
    json |-> "sc_rollup_commitment_period_in_blocks" |> as_int
  in
  let max_lookahead_in_blocks =
    json |-> "sc_rollup_max_lookahead_in_blocks" |> as_int32
  in
  let max_active_outbox_levels =
    json |-> "sc_rollup_max_active_outbox_levels" |> as_int32
  in
  let max_outbox_messages_per_level =
    json |-> "sc_rollup_max_outbox_messages_per_level" |> as_int
  in
  let number_of_sections_in_dissection =
    json |-> "sc_rollup_number_of_sections_in_dissection" |> as_int
  in
  return
    {
      origination_size;
      challenge_window_in_blocks;
      max_number_of_messages_per_commitment_period;
      stake_amount;
      commitment_period_in_blocks;
      max_lookahead_in_blocks;
      max_active_outbox_levels;
      max_outbox_messages_per_level;
      number_of_sections_in_dissection;
    }

(* List of scoru errors messages used in tests below. *)

let commit_too_recent =
  "Attempted to cement a commitment before its refutation deadline"

let parent_not_lcc = "Parent is not the last cemented commitment"

let disputed_commit = "Attempted to cement a disputed commitment"

let commit_doesnt_exit = "Commitment scc\\w+\\sdoes not exist"

let make_parameter name value =
  Option.map (fun v -> ([name], Option.some @@ Int.to_string v)) value
  |> Option.to_list

let test ~__FILE__ ?(tags = []) title f =
  let tags = "sc_rollup" :: tags in
  Protocol.register_test ~__FILE__ ~title ~tags f

let regression_test ~__FILE__ ?(tags = []) title f =
  let tags = "sc_rollup" :: tags in
  Protocol.register_regression_test ~__FILE__ ~title ~tags f

let setup ?commitment_period ?challenge_window ?timeout f ~protocol =
  let parameters =
    make_parameter "sc_rollup_commitment_period_in_blocks" commitment_period
    @ make_parameter "sc_rollup_challenge_window_in_blocks" challenge_window
    @ make_parameter "sc_rollup_timeout_period_in_blocks" timeout
    @ [(["sc_rollup_enable"], Some "true")]
  in
  let base = Either.right (protocol, None) in
  let* parameter_file = Protocol.write_parameter_file ~base parameters in
  let nodes_args =
    Node.
      [
        Synchronisation_threshold 0; History_mode (Full None); No_bootstrap_peers;
      ]
  in
  let* node, client =
    Client.init_with_protocol ~parameter_file `Client ~protocol ~nodes_args ()
  in
  let operator = Constant.bootstrap1.alias in
  f node client operator

let get_sc_rollup_commitment_period_in_blocks client =
  let* constants = get_sc_rollup_constants client in
  return constants.commitment_period_in_blocks

let sc_rollup_node_rpc sc_node service =
  let* curl = RPC.Curl.get () in
  match curl with
  | None -> return None
  | Some curl ->
      let url =
        Printf.sprintf "%s/%s" (Sc_rollup_node.endpoint sc_node) service
      in
      let* response = curl ~url in
      return (Some response)

type test = {variant : string; tags : string list; description : string}

(** This helper injects an SC rollup origination via tezos-client. Then it
    bakes to include the origination in a block. It returns the address of the
    originated rollup *)
let originate_sc_rollup ?(hooks = hooks) ?(burn_cap = Tez.(of_int 9999999))
    ?(src = "bootstrap1") ?(kind = "arith") ?(parameters_ty = "string")
    ?(boot_sector = boot_sector_of kind) client =
  let* sc_rollup =
    Client.Sc_rollup.(
      originate ~hooks ~burn_cap ~src ~kind ~parameters_ty ~boot_sector client)
  in
  let* () = Client.bake_for_and_wait client in
  return sc_rollup

(* Configuration of a rollup node
   ------------------------------

   A rollup node has a configuration file that must be initialized.
*)
let with_fresh_rollup ?kind ?boot_sector f tezos_node tezos_client operator =
  let* sc_rollup =
    originate_sc_rollup ?kind ?boot_sector ~src:operator tezos_client
  in
  let sc_rollup_node =
    Sc_rollup_node.create
      Operator
      tezos_node
      tezos_client
      ~default_operator:operator
  in
  let* configuration_filename =
    Sc_rollup_node.config_init sc_rollup_node sc_rollup
  in
  f sc_rollup sc_rollup_node configuration_filename

(* TODO: https://gitlab.com/tezos/tezos/-/issues/2933
   Many tests can be refactored using test_scenario. *)
let test_scenario ~kind ?boot_sector ?commitment_period ?challenge_window
    ?timeout {variant; tags; description} scenario =
  let tags = tags @ [kind; variant] in
  regression_test
    ~__FILE__
    ~tags
    (Printf.sprintf "%s - %s (%s)" kind description variant)
    (fun protocol ->
      setup ?commitment_period ?challenge_window ~protocol ?timeout
      @@ fun node client ->
      ( with_fresh_rollup ~kind ?boot_sector
      @@ fun sc_rollup sc_rollup_node _filename ->
        scenario protocol sc_rollup_node sc_rollup node client )
        node
        client)

let inbox_level (_hash, (commitment : Sc_rollup_client.commitment), _level) =
  commitment.inbox_level

let number_of_ticks (_hash, (commitment : Sc_rollup_client.commitment), _level)
    =
  commitment.number_of_ticks

let last_cemented_commitment_hash_with_level ~sc_rollup client =
  let* json =
    RPC.Client.call client
    @@ RPC
       .get_chain_block_context_sc_rollup_last_cemented_commitment_hash_with_level
         sc_rollup
  in
  let hash = JSON.(json |-> "hash" |> as_string) in
  let level = JSON.(json |-> "level" |> as_int) in
  return (hash, level)

let get_staked_on_commitment ~sc_rollup ~staker client =
  let* json =
    RPC.Client.call client
    @@ RPC.get_chain_block_context_sc_rollup_staker_staked_on_commitment
         ~sc_rollup
         staker
  in
  let hash = JSON.(json |-> "hash" |> as_string) in
  return hash

let hash (hash, (_ : Sc_rollup_client.commitment), _level) = hash

let first_published_at_level (_hash, (_ : Sc_rollup_client.commitment), level) =
  level

let predecessor (_hash, {Sc_rollup_client.predecessor; _}, _level) = predecessor

let cement_commitment ?(src = "bootstrap1") ?fail ~sc_rollup ~hash client =
  let p =
    Client.Sc_rollup.cement_commitment ~hooks ~dst:sc_rollup ~src ~hash client
  in
  match fail with
  | None ->
      let*! () = p in
      Client.bake_for_and_wait client
  | Some failure ->
      let*? process = p in
      Process.check_error ~msg:(rex failure) process

let publish_commitment ?(src = Constant.bootstrap1.public_key_hash) ~commitment
    client sc_rollup =
  let ({compressed_state; inbox_level; predecessor; number_of_ticks}
        : Sc_rollup_client.commitment) =
    commitment
  in
  Client.Sc_rollup.publish_commitment
    ~hooks
    ~src
    ~sc_rollup
    ~compressed_state
    ~inbox_level
    ~predecessor
    ~number_of_ticks
    client

(*

   Tests
   =====

*)

(* Originate a new SCORU
   ---------------------

   - Rollup addresses are fully determined by operation hashes and origination nonce.
*)
let test_origination ~kind =
  regression_test
    ~tags:["sc_rollup"; kind]
    ~__FILE__
    (Format.asprintf "%s - origination of a SCORU executes without error" kind)
    (fun protocol ->
      setup ~protocol @@ fun _node client bootstrap1_key ->
      let* _sc_rollup = originate_sc_rollup ~kind ~src:bootstrap1_key client in
      unit)

(* Initialize configuration
   ------------------------

   Can use CLI to initialize the rollup node config file
 *)
let test_rollup_node_configuration ~kind =
  regression_test
    ~__FILE__
    ~tags:["sc_rollup"]
    "configuration of a smart contract optimistic rollup node"
    (fun protocol ->
      setup ~protocol @@ with_fresh_rollup ~kind
      @@ fun _sc_rollup _sc_rollup_node filename ->
      let read_configuration =
        let open Ezjsonm in
        match from_channel (open_in filename) with
        | `O fields ->
            (* Remove "data-dir" and "rpc-port" as they are non deterministic. *)
            `O
              (List.filter
                 (fun (s, _) ->
                   match s with "data-dir" | "rpc-port" -> false | _ -> true)
                 fields)
            |> to_string
        | _ ->
            failwith "The configuration file does not have the expected format."
      in
      Log.info "Read configuration:\n %s" read_configuration ;
      return ())

(* Launching a rollup node
   -----------------------

   A running rollup node can be asked the address of the rollup it is
   interacting with.
*)
let test_rollup_node_running ~kind =
  test
    ~__FILE__
    ~tags:["sc_rollup"; "run"; kind]
    (Format.asprintf "%s - running a smart contract rollup node" kind)
    (fun protocol ->
      setup ~protocol @@ with_fresh_rollup ~kind
      @@ fun sc_rollup sc_rollup_node _filename ->
      let* () = Sc_rollup_node.run sc_rollup_node in
      let* sc_rollup_from_rpc =
        sc_rollup_node_rpc sc_rollup_node "global/sc_rollup_address"
      in
      match sc_rollup_from_rpc with
      | None ->
          (* No curl, no check. *)
          failwith "Please install curl"
      | Some sc_rollup_from_rpc ->
          let sc_rollup_from_rpc = JSON.as_string sc_rollup_from_rpc in
          if sc_rollup_from_rpc <> sc_rollup then
            failwith
              (Printf.sprintf
                 "Expecting %s, got %s when we query the sc rollup node RPC \
                  address"
                 sc_rollup
                 sc_rollup_from_rpc)
          else return ())

(* Interacting with a rollup node through a rollup client
   ------------------------------------------------------

   When a rollup node is running, a rollup client can ask this
   node its rollup address.
*)
let test_rollup_client_gets_address ~kind =
  regression_test
    ~__FILE__
    ~tags:["sc_rollup"; "run"; "client"]
    "getting a smart-contract rollup address through the client"
    (fun protocol ->
      setup ~protocol @@ with_fresh_rollup ~kind
      @@ fun sc_rollup sc_rollup_node _filename ->
      let* () = Sc_rollup_node.run sc_rollup_node in
      let sc_client = Sc_rollup_client.create sc_rollup_node in
      let* sc_rollup_from_client =
        Sc_rollup_client.sc_rollup_address sc_client
      in
      if sc_rollup_from_client <> sc_rollup then
        failwith
          (Printf.sprintf
             "Expecting %s, got %s when the client asks for the sc rollup \
              address"
             sc_rollup
             sc_rollup_from_client) ;
      return ())

(* Fetching the initial level of a sc rollup
    -----------------------------------------

   We can fetch the level when a smart contract rollup was
   originated from the context.
*)
let test_rollup_get_genesis_info ~kind =
  regression_test
    ~__FILE__
    ~tags:["sc_rollup"; "genesis_info"; kind]
    (Format.asprintf "%s - get genesis info of a sc rollup" kind)
    (fun protocol ->
      setup ~protocol @@ fun node client bootstrap ->
      let* current_level = RPC.get_current_level client in
      ( with_fresh_rollup ~kind @@ fun sc_rollup _sc_rollup_node _filename ->
        (* Bake 10 blocks to be sure that the initial level of rollup is different
           from the current level. *)
        let* _ = repeat 10 (fun () -> Client.bake_for_and_wait client) in
        let* genesis_info =
          RPC.Client.call client
          @@ RPC.get_chain_block_context_sc_rollup_genesis_info sc_rollup
        in
        (* 1 Block for activating alpha + 1 block for originating the rollup
           the rollup initial level should be 2 *)
        Check.(
          (JSON.(genesis_info |-> "level" |> as_int)
          = JSON.as_int (JSON.get "level" current_level) + 1)
            int
            ~error_msg:"expected value %L, got %R") ;
        return () )
        node
        client
        bootstrap)

(* Fetching the last cemented commitment info for a sc rollup
    ----------------------------------------------------------

   We can fetch the hash and level of the last cemented commitment. Initially,
   this corresponds to `(Sc_rollup.Commitment_hash.zero, origination_level)`.
*)

(* TODO: https://gitlab.com/tezos/tezos/-/issues/2944
   Revisit this test once the rollup node can cement commitments. *)
let test_rollup_get_chain_block_context_sc_rollup_last_cemented_commitment_hash_with_level
    ~kind =
  regression_test
    ~__FILE__
    ~tags:["sc_rollup"; "lcc_hash_with_level"; kind]
    (Format.asprintf
       "%s - get last cemented commitment hash and inbox level of a sc rollup"
       kind)
    (fun protocol ->
      setup ~protocol @@ fun node client bootstrap ->
      ( with_fresh_rollup ~kind @@ fun sc_rollup _sc_rollup_node _filename ->
        let* origination_level = RPC.get_current_level client in

        (* Bake 10 blocks to be sure that the origination_level of rollup is different
           from the level of the head node. *)
        let* () = repeat 10 (fun () -> Client.bake_for_and_wait client) in
        let* hash, level =
          last_cemented_commitment_hash_with_level ~sc_rollup client
        in
        let* genesis_info =
          RPC.Client.call client
          @@ RPC.get_chain_block_context_sc_rollup_genesis_info sc_rollup
        in
        let genesis_hash =
          JSON.(genesis_info |-> "commitment_hash" |> as_string)
        in
        Check.(
          (hash = genesis_hash) string ~error_msg:"expected value %L, got %R") ;
        (* The level of the last cemented commitment should correspond to the
           rollup origination level. *)
        Check.(
          (level = JSON.(origination_level |-> "level" |> as_int))
            int
            ~error_msg:"expected value %L, got %R") ;
        return () )
        node
        client
        bootstrap)

(* Pushing message in the inbox
   ----------------------------

   A message can be pushed to a smart-contract rollup inbox through
   the Tezos node. Then we can observe that the messages are included in the
   inbox.
*)
let send_message client sc_rollup msg =
  let* () =
    Client.Sc_rollup.send_message
      ~hooks
      ~src:Constant.bootstrap2.alias
      ~dst:sc_rollup
      ~msg
      client
  in
  Client.bake_for_and_wait client

let send_messages ?batch_size n sc_rollup client =
  let messages =
    List.map
      (fun i ->
        let batch_size = match batch_size with None -> i | Some v -> v in
        let json =
          `A (List.map (fun _ -> `String "CAFEBABE") (range 1 batch_size))
        in
        "text:" ^ Ezjsonm.to_string json)
      (range 1 n)
  in
  Lwt_list.iter_s (fun msg -> send_message client sc_rollup msg) messages

let to_text_messages_arg msgs =
  let json = Ezjsonm.list Ezjsonm.string msgs in
  "text:" ^ Ezjsonm.to_string ~minify:true json

let send_text_messages client sc_rollup msgs =
  send_message client sc_rollup (to_text_messages_arg msgs)

let parse_inbox json =
  let go () =
    let inbox = JSON.as_object json in
    return
      ( List.assoc "current_level_hash" inbox |> JSON.as_string,
        List.assoc "nb_messages_in_commitment_period" inbox |> JSON.as_int )
  in
  Lwt.catch go @@ fun exn ->
  failwith
    (Printf.sprintf
       "Unable to parse inbox %s\n%s"
       (JSON.encode json)
       (Printexc.to_string exn))

let get_inbox_from_tezos_node sc_rollup client =
  let* inbox =
    RPC.Client.call client
    @@ RPC.get_chain_block_context_sc_rollup_inbox sc_rollup
  in
  parse_inbox inbox

let get_inbox_from_sc_rollup_node sc_rollup_node =
  let* inbox = sc_rollup_node_rpc sc_rollup_node "global/inbox" in
  match inbox with
  | None -> failwith "Unable to retrieve inbox from sc rollup node"
  | Some inbox -> parse_inbox inbox

let test_rollup_inbox_size ~kind =
  regression_test
    ~__FILE__
    ~tags:["sc_rollup"; "inbox"; kind]
    (Format.asprintf
       "%s - pushing messages in the inbox - check inbox size"
       kind)
    (fun protocol ->
      setup ~protocol @@ fun node client ->
      ( with_fresh_rollup ~kind @@ fun sc_rollup _sc_rollup_node _filename ->
        let n = 10 in
        let* () = send_messages n sc_rollup client in
        let* _, inbox_msg_during_commitment_period =
          get_inbox_from_tezos_node sc_rollup client
        in
        return
        @@ Check.(
             (inbox_msg_during_commitment_period = n * (n + 1) / 2)
               int
               ~error_msg:"expected value %R, got %L") )
        node
        client)

module Sc_rollup_inbox = struct
  open Tezos_context_encoding.Context

  module Store = struct
    module Maker = Irmin_pack_mem.Maker (Conf)
    include Maker.Make (Schema)
    module Schema = Tezos_context_encoding.Context.Schema
  end

  include Tezos_context_helpers.Context.Make_tree (Conf) (Store)

  (* An external message is prefixed with a tag whose length is one byte, and
     whose value is 1. *)
  let encode_external_message message =
    let prefix = "\001" in
    Bytes.of_string (prefix ^ message)

  (*
      The hash for empty messages is the hash of empty bytes, and not of an empty
      tree.

      The hash for non-empty messages is the hash of the tree, where each message
      payload sits at the key [[message_index, "payload"]], where [message_index]
      is the index of the current message relative to the first message.

      The [message_counter] is reset to zero when the inbox level increments (and
      therefore [current_messages] are zero-indexed in the tree).
  *)
  let rec build_current_messages_tree counter tree messages =
    match messages with
    | [] -> return tree
    | message :: rest ->
        let key = Data_encoding.Binary.to_string_exn Data_encoding.z counter in
        let payload = encode_external_message message in
        let* tree = add tree ["message"; key] payload in
        build_current_messages_tree (Z.succ counter) tree rest

  module P = Tezos_protocol_alpha.Protocol

  let predict_current_messages_hash level current_messages =
    let open P.Alpha_context.Sc_rollup in
    let open Lwt.Syntax in
    let level_bytes =
      Data_encoding.Binary.to_bytes_exn
        P.Raw_level_repr.encoding
        (P.Raw_level_repr.of_int32_exn level)
    in
    let* tree = add (empty ()) ["level"] level_bytes in
    let* tree = build_current_messages_tree Z.zero tree current_messages in
    let context_hash = hash tree in
    let test =
      Data_encoding.Binary.to_bytes_exn
        Tezos_base.TzPervasives.Context_hash.encoding
        context_hash
    in
    return (Inbox.Hash.of_bytes_exn test)
end

let fetch_messages_from_block sc_rollup client =
  let* ops = RPC.get_operations client in
  let messages =
    ops |> JSON.as_list
    |> List.concat_map JSON.as_list
    |> List.concat_map (fun op -> JSON.(op |-> "contents" |> as_list))
    |> List.filter_map (fun op ->
           if
             JSON.(op |-> "kind" |> as_string) = "sc_rollup_add_messages"
             && JSON.(op |-> "rollup" |> as_string) = sc_rollup
           then Some JSON.(op |-> "message" |> as_list)
           else None)
    |> List.hd
    |> List.map (fun message -> JSON.(message |> as_string))
  in
  return messages

(* TODO what does it test?
   It doesn't use the rollup node.
 *)
let test_rollup_inbox_current_messages_hash ~kind =
  regression_test
    ~__FILE__
    ~tags:["sc_rollup"; "inbox"; kind]
    (Format.asprintf
       "%s - pushing messages in the inbox - current messages hash"
       kind)
    (fun protocol ->
      setup ~protocol @@ fun node client ->
      ( with_fresh_rollup ~kind @@ fun sc_rollup _sc_rollup_node _filename ->
        let gen_message_batch from until =
          List.map
            (fun x ->
              Printf.sprintf "hello, message number %s" (Int.to_string x))
            (range from until)
        in
        let prepare_batch messages =
          messages
          |> List.map (Printf.sprintf "\"%s\"")
          |> String.concat ", " |> Printf.sprintf "text:[%s]"
        in
        let open Tezos_protocol_alpha.Protocol.Alpha_context.Sc_rollup in
        (* no messages have been sent *)
        let* pristine_hash, nb_available_messages =
          get_inbox_from_tezos_node sc_rollup client
        in
        let () =
          Check.((nb_available_messages = 0) int)
            ~error_msg:"0 messages expected in the inbox"
        in
        let* expected = Sc_rollup_inbox.predict_current_messages_hash 0l [] in
        let () =
          Check.(
            (Inbox.Hash.to_b58check expected = pristine_hash)
              string
              ~error_msg:"FIRST: expected pristine hash %L, got %R")
        in
        (*
           send messages, and assert that
           - the hash has changed
           - the hash matches the 'predicted' hash from the messages we sent
        *)
        let fst_batch = gen_message_batch 0 4 in
        let* () = send_message client sc_rollup @@ prepare_batch fst_batch in
        let* fst_batch_hash, _ = get_inbox_from_tezos_node sc_rollup client in
        let () =
          Check.(
            (pristine_hash <> fst_batch_hash)
              string
              ~error_msg:
                "expected current messages hash to change when messages sent")
        in
        let* expected =
          Sc_rollup_inbox.predict_current_messages_hash 3l fst_batch
        in
        let () =
          Check.(
            (Inbox.Hash.to_b58check expected = fst_batch_hash)
              string
              ~error_msg:"2 expected first batch hash %L, got %R")
        in
        (*
           send more messages, and assert that
           - the messages can be retrieved from the latest block
           - the hash matches the 'predicted' hash from the messages we sent
        *)
        let snd_batch = gen_message_batch 5 10 in
        let* () = send_message client sc_rollup @@ prepare_batch snd_batch in
        let* messages = fetch_messages_from_block sc_rollup client in
        let () =
          Check.(
            (messages = snd_batch)
              (list string)
              ~error_msg:"expected messages:\n%R\nretrieved:\n%L")
        in
        let* snd_batch_hash, _ = get_inbox_from_tezos_node sc_rollup client in
        let* expected =
          Sc_rollup_inbox.predict_current_messages_hash 4l snd_batch
        in
        let () =
          Check.(
            (Inbox.Hash.to_b58check expected = snd_batch_hash)
              string
              ~error_msg:"expected second batch hash %L, got %R")
        in
        unit )
        node
        client)

(* Synchronizing the inbox in the rollup node
   ------------------------------------------

   For each new head set by the Tezos node, the rollup node retrieves
   the messages of its rollup and maintains its internal inbox in a
   persistent state stored in its data directory. This process can
   handle Tezos chain reorganization and can also catch up to ensure a
   tight synchronization between the rollup and the layer 1 chain.

   In addition, this maintenance includes the computation of a Merkle
   tree which must have the same root hash as the one stored by the
   protocol in the context.
*)
let test_rollup_inbox_of_rollup_node variant scenario ~kind =
  regression_test
    ~__FILE__
    ~tags:["sc_rollup"; "inbox"; "node"; variant; kind]
    (Printf.sprintf
       "%s - maintenance of inbox in the rollup node (%s)"
       kind
       variant)
    (fun protocol ->
      setup ~protocol @@ fun node client ->
      ( with_fresh_rollup ~kind @@ fun sc_rollup sc_rollup_node _filename ->
        let* () = scenario protocol sc_rollup_node sc_rollup node client in
        let* inbox_from_sc_rollup_node =
          get_inbox_from_sc_rollup_node sc_rollup_node
        in
        let* inbox_from_tezos_node =
          get_inbox_from_tezos_node sc_rollup client
        in
        return
        @@ Check.(
             (inbox_from_sc_rollup_node = inbox_from_tezos_node)
               (tuple2 string int)
               ~error_msg:"expected value %R, got %L") )
        node
        client)

let basic_scenario _protocol sc_rollup_node sc_rollup _node client =
  let num_messages = 2 in
  let expected_level =
    (* We start at level 2 and each message also bakes a block. With 2 messages being sent, we
       must end up at level 4. *)
    4
  in
  let* () = Sc_rollup_node.run sc_rollup_node in
  Log.info "before sending messages\n" ;
  let* () = send_messages num_messages sc_rollup client in
  let* level = Client.level client in
  Log.info "level: %d\n" level ;
  let* _ =
    Sc_rollup_node.wait_for_level ~timeout:3. sc_rollup_node expected_level
  in
  return ()

(* We can terminate the rollup node. *)
let sc_rollup_node_stops_scenario _protocol sc_rollup_node sc_rollup _node
    client =
  let num_messages = 2 in
  let expected_level =
    (* We start at level 2 and each message also bakes a block. With 2 messages being sent twice, we
       must end up at level 6. *)
    6
  in
  let* () = Sc_rollup_node.run sc_rollup_node in
  let* () = send_messages num_messages sc_rollup client in
  let* () = Sc_rollup_node.terminate sc_rollup_node in
  let* () = send_messages num_messages sc_rollup client in
  let* () = Sc_rollup_node.run sc_rollup_node in
  let* _ =
    Sc_rollup_node.wait_for_level ~timeout:3. sc_rollup_node expected_level
  in
  return ()

let sc_rollup_node_disconnects_scenario _protocol sc_rollup_node sc_rollup node
    client =
  let num_messages = 2 in
  let level = Node.get_level node in
  Log.info "we are at level %d" level ;
  let* () = Sc_rollup_node.run sc_rollup_node in
  let* () = send_messages num_messages sc_rollup client in
  let* level =
    Sc_rollup_node.wait_for_level sc_rollup_node (level + num_messages)
  in
  Log.info "Terminating Tezos node" ;
  let* () = Node.terminate node in
  Log.info "Waiting before restarting Tezos node" ;
  let* () = Lwt_unix.sleep 3. in
  Log.info "Restarting Tezos node" ;
  let* () = Node.run node Node.[Connections 0; Synchronisation_threshold 0] in
  let* () = Node.wait_for_ready node in
  let* () = send_messages num_messages sc_rollup client in
  let* _ =
    Sc_rollup_node.wait_for_level sc_rollup_node (level + num_messages)
  in
  return ()

(* TODO what does this test? Does it use the rollup node? *)
let sc_rollup_node_handles_chain_reorg protocol sc_rollup_node sc_rollup node
    client =
  let num_messages = 1 in

  setup ~protocol @@ fun node' client' _ ->
  let* () = Client.Admin.trust_address client ~peer:node'
  and* () = Client.Admin.trust_address client' ~peer:node in
  let* () = Client.Admin.connect_address client ~peer:node' in

  let* () = Sc_rollup_node.run sc_rollup_node in
  let* () = send_messages num_messages sc_rollup client in
  (* Since we start at level 2, sending 1 message (which also bakes a block) must cause the nodes to
     observe level 3. *)
  let* _ = Node.wait_for_level node 3 in
  let* _ = Node.wait_for_level node' 3 in
  let* _ = Sc_rollup_node.wait_for_level ~timeout:3. sc_rollup_node 3 in
  Log.info "Nodes are synchronized." ;

  let divergence () =
    let* identity' = Node.wait_for_identity node' in
    let* () = Client.Admin.kick_peer client ~peer:identity' in
    let* () = send_messages num_messages sc_rollup client in
    (* +1 block for [node] *)
    let* _ = Node.wait_for_level node 4 in

    let* () = send_messages num_messages sc_rollup client' in
    let* () = send_messages num_messages sc_rollup client' in
    (* +2 blocks for [node'] *)
    let* _ = Node.wait_for_level node' 5 in
    Log.info "Nodes are following distinct branches." ;
    return ()
  in

  let trigger_reorg () =
    let* () = Client.Admin.connect_address client ~peer:node' in
    let* _ = Node.wait_for_level node 5 in
    Log.info "Nodes are synchronized again." ;
    return ()
  in

  let* () = divergence () in
  let* () = trigger_reorg () in
  (* After bringing [node'] back, our SCORU node should see that there is a more attractive head at
     level 5. *)
  let* _ = Sc_rollup_node.wait_for_level ~timeout:3. sc_rollup_node 5 in
  return ()

(* One can retrieve the list of originated SCORUs.
   -----------------------------------------------
*)
let with_fresh_rollups ~kind n f node client operator =
  let rec go n addrs k =
    if n < 1 then k addrs
    else
      with_fresh_rollup
        ~kind
        (fun addr _ _ -> go (n - 1) (String_set.add addr addrs) k)
        node
        client
        operator
  in
  go n String_set.empty f

let test_rollup_list ~kind =
  let open Lwt.Syntax in
  let go node client bootstrap1 =
    let* rollups =
      RPC.Client.call client @@ RPC.get_chain_block_context_sc_rollup ()
    in
    let rollups = JSON.as_list rollups in
    let () =
      match rollups with
      | _ :: _ ->
          failwith "Expected initial list of originated SCORUs to be empty"
      | [] -> ()
    in

    with_fresh_rollups
      ~kind
      10
      (fun scoru_addresses ->
        let* () = Client.bake_for_and_wait client in
        let+ rollups =
          RPC.Client.call client @@ RPC.get_chain_block_context_sc_rollup ()
        in
        let rollups =
          JSON.as_list rollups |> List.map JSON.as_string |> String_set.of_list
        in
        Check.(
          (rollups = scoru_addresses)
            (comparable_module (module String_set))
            ~error_msg:"%L %R"))
      node
      client
      bootstrap1
  in

  regression_test
    ~__FILE__
    ~tags:["sc_rollup"; "list"]
    "list originated rollups"
    (fun protocol -> setup ~protocol go)

(* Make sure the rollup node boots into the initial state.
   -------------------------------------------------------

   When a rollup node starts, we want to make sure that in the absence of
   messages it will boot into the initial state.
*)
let test_rollup_node_boots_into_initial_state ~kind =
  let go client sc_rollup sc_rollup_node =
    let* genesis_info =
      RPC.Client.call ~hooks client
      @@ RPC.get_chain_block_context_sc_rollup_genesis_info sc_rollup
    in
    let init_level = JSON.(genesis_info |-> "level" |> as_int) in

    let* () = Sc_rollup_node.run sc_rollup_node in
    let sc_rollup_client = Sc_rollup_client.create sc_rollup_node in

    let* level =
      Sc_rollup_node.wait_for_level ~timeout:3. sc_rollup_node init_level
    in
    Check.(level = init_level)
      Check.int
      ~error_msg:"Current level has moved past origination level (%L = %R)" ;

    let* ticks = Sc_rollup_client.total_ticks ~hooks sc_rollup_client in
    Check.(ticks = 0)
      Check.int
      ~error_msg:"Unexpected initial tick count (%L = %R)" ;

    let* status = Sc_rollup_client.status ~hooks sc_rollup_client in
    let expected_status =
      match kind with
      | "arith" -> "Halted"
      | "wasm_2_0_0" -> "Computing"
      | _ -> raise (Invalid_argument kind)
    in
    Check.(status = expected_status)
      Check.string
      ~error_msg:"Unexpected PVM status (%L = %R)" ;

    Lwt.return_unit
  in

  regression_test
    ~__FILE__
    ~tags:["sc_rollup"; "run"; "node"; kind]
    (Format.asprintf "%s - node boots into the initial state" kind)
    (fun protocol ->
      setup ~protocol @@ fun node client ->
      with_fresh_rollup
        ~kind
        (fun sc_rollup sc_rollup_node _filename ->
          go client sc_rollup sc_rollup_node)
        node
        client)

(* Ensure the PVM is transitioning upon incoming messages.
   -------------------------------------------------------

   When the rollup node receives messages, we like to see evidence that the PVM
   has advanced.

*)

(* Read the chosen `wasm_kernel` into memory. *)
let read_kernel name =
  let open Tezt.Base in
  let kernel_file =
    project_root // Filename.dirname __FILE__ // "wasm_kernel"
    // (name ^ ".wasm")
  in
  read_file kernel_file

(* Kernel with allocation & simple computation only.
   9863 bytes long - will be split into 3 chunks. *)
let _computation_kernel () = read_kernel "computation"

let computation_kernel () =
  "00000026870061736d01000000014a0c60027f7f017f60027f7f0060037f7f7f017f60000060017f0060037f7f7f0060047f7f7f7f017f60047f7f7f7f0060017f017f60057f7f7f7f7f017f60017f017e60057f7f7f7f7f00034746030400050601000506040700080902070407000803080404040507010a0a0004050008010104010101010b010200000101010301010004020501020a0000080808000b00020204050170011d1d05030100110619037f01418080c0000b7f0041948cc0000b7f0041a08cc0000b073304066d656d6f727902000b6b65726e656c5f6e65787400000a5f5f646174615f656e6403010b5f5f686561705f6261736503020922010041010b1c013c090a0b0c1112131023171c161d18262728292c2d2e35413d363b0afa4646860201057f23808080800041106b22002480808080001094808080000240024041002802e083c080000d004100417f3602e083c080000240024041002802e483c080002201450d00200128020041016a210241002802ec83c08000210341002802e883c0800021040c010b410441041082808080002201450d0241002104410020013602e483c080002001410036020041012102410121030b20012002360200410020033602e883c080004100200420036a3602ec83c08000410041002802e083c0800041016a3602e083c08000200041106a2480808080000f0b41b480c080004110200041086a41c480c0800041a480c0800010c280808000000b4104410410b180808000000b02000b1301017f20002001108680808000210220020f0b0f002000200120021087808080000f0b1701017f2000200120022003108880808000210420040f0b0d002000200110b4808080000f0b120041f083c0800020002001108e808080000b140041f083c08000200020012002108f808080000b4501017f024041f083c0800020032002108e808080002204450d002004200020032001200120034b1b10c5808080001a41f083c08000200020012002108f808080000b20040b02000b7701017f02400240200241027422022003410374418080016a2203200220034b1b418780046a220441107640002203417f470d0041012102410021030c010b20034110742203420037030041002102200341003602082003200320044180807c716a4102723602000b20002003360204200020023602000b05004180040b040041010bef0401087f024020022802002205450d002001417f6a210620004102742107410020016b21080340200541086a2109024002402005280208220a4101710d00200521010c010b03402009200a417e71360200024002402005280204220a417c7122090d00410021010c010b4100200920092d00004101711b21010b02402005280200220b417c71220c450d004100200c200b4102711b220b450d00200b200b2802044103712009723602042005280204220a417c7121090b02402009450d00200920092802004103712005280200417c71723602002005280204210a0b2005200a41037136020420052005280200220941037136020002402009410271450d00200120012802004102723602000b20022001360200200141086a2109200121052001280208220a4101710d000b0b02402001280200417c71220a200141086a22056b2007490d00024002402005200320002004280210118080808000004102746a41086a200a20076b200871220a4d0d0020062005710d0220022009280200417c7136020020012001280200410172360200200121050c010b200a4100360200200a41786a2205420037020020052001280200417c7136020002402001280200220a417c71220b450d004100200b200a4102711b220a450d00200a200a2802044103712005723602040b2005200528020441037120017236020420092009280200417e71360200200120012802002209410371200572220a3602000240024020094102710d00200528020021010c010b2001200a417d713602002005200528020041027222013602000b200520014101723602000b200541086a0f0b20022001280208220536020020050d000b0b41000bac0301037f23808080800041106b22032480808080000240024020010d00200221010c010b200141036a220441027621050240200241054f0d002005417f6a220141ff014b0d00200320003602082003200020014102746a41046a41002001418002491b220028020036020c0240200520022003410c6a200341086a41ec80c08000108d8080800022010d002003200341086a200520021091808080004100210120032802000d0020032802042201200328020c3602082003200136020c200520022003410c6a200341086a41ec80c08000108d8080800021010b2000200328020c3602000c010b2003200028020036020c0240200520022003410c6a41d480c0800041d480c08000108d8080800022010d0002402004417c7122012002410374418080016a2204200120044b1b418780046a220441107640002201417f470d00410021010c010b20014110742201200328020c360208200141003602042001200120044180807c716a4102723602002003200136020c200520022003410c6a41d480c0800041d480c08000108d8080800021010b2000200328020c3602000b200341106a24808080800020010be60501067f23808080800041106b220424808080800002402001450d002002450d000240200341054f0d00200241036a410276417f6a220341ff014b0d0020014100360200200141786a22022002280200417e713602002004200036020c200020034102746a41046a22002802002103024002402004410c6a109380808000450d00024002402001417c6a2205280200417c712206450d00200628020022074101710d0002400240024020022802002208417c7122010d00200621090c010b200621094100200120084102711b2208450d002008200828020441037120067236020420052802002201417c712209450d012002280200417c712101200928020021070b20092001200741037172360200200528020021010b200520014103713602002002200228020022014103713602002001410271450d01200620062802004102723602000c010b20022802002206417c712205450d014100200520064102711b2206450d0120062d00004101710d0120012006280208417c71360200200620024101723602080b200321020c010b200120033602000b200020023602000c010b20014100360200200141786a220220022802002203417e71360200200028020021050240024002402001417c6a2207280200417c712206450d00200628020022094101710d000240024002402003417c7122010d00200621080c010b200621084100200120034102711b2203450d002003200328020441037120067236020420072802002201417c712208450d012002280200417c712101200828020021090b20082001200941037172360200200728020021010b200720014103713602002002200228020022014103713602002001410271450d01200620062802004102723602000c010b2003417c712206450d014100200620034102711b2203450d0120032d00004101710d0120012003280208417c71360200200320024101723602080b200020053602000c010b20012005360200200020023602000b200441106a2480808080000b02000b960201027f23808080800041106b220424808080800020042001280200220528020036020c024002400240200241026a220220026c220241801020024180104b1b220141042004410c6a418481c08000418481c08000108d808080002202450d002005200428020c3602000c010b2004418481c0800020014104108a80808000024002402004280200450d002005200428020c3602000c010b20042802042202200428020c3602082004200236020c200141042004410c6a418481c08000418481c08000108d8080800021022005200428020c36020020020d010b410121010c010b200242003702042002200220014102746a410272360200410021010b2000200236020420002001360200200441106a2480808080000b040020010b040041000b02000b040000000b02000b2a01017f0240200041046a2802002201450d0020002802002200450d002000200141011083808080000b0b2a01017f024020002802042201450d00200041086a2802002200450d002001200041011083808080000b0bdb0101027f23808080800041206b22032480808080000240200120026a22022001490d00200041046a280200220441017422012002200120024b1b22014108200141084b1b2101024002402004450d00200341106a41086a410136020020032004360214200320002802003602100c010b200341003602100b200320014101200341106a109a8080800002402003280200450d00200341086a2802002200450d012003280204200010b180808000000b20032802042102200041046a200136020020002002360200200341206a2480808080000f0b10b280808000000bb50101027f0240024002400240024002400240024002402002450d004101210420014100480d0120032802002205450d02200328020422030d0520010d03200221030c040b20002001360204410121040b410021010c060b20010d00200221030c010b2001200210828080800021030b2003450d010c020b200520032002200110848080800022030d010b20002001360204200221010c010b20002003360204410021040b20002004360200200041086a20013602000bdb0101037f23808080800041206b22022480808080000240200141016a22032001490d00200041046a280200220441017422012003200120034b1b22014108200141084b1b2101024002402004450d00200241106a41086a410136020020022004360214200220002802003602100c010b200241003602100b200220014101200241106a109a8080800002402002280200450d00200241086a2802002200450d012002280204200010b180808000000b20022802042103200041046a200136020020002003360200200241206a2480808080000f0b10b280808000000b0c0042f6e2f8b1f2e1afe7050b0d0042d1ae98c49983b2f7847f0bf70201037f23808080800041106b220224808080800002400240024002402001418001490d002002410036020c20014180104f0d0120022001413f71418001723a000d2002200141067641c001723a000c410221010c020b024020002802082203200041046a280200470d0020002003109b80808000200028020821030b2000200341016a360208200028020020036a20013a00000c020b0240200141808004490d0020022001413f71418001723a000f2002200141127641f001723a000c20022001410676413f71418001723a000e20022001410c76413f71418001723a000d410421010c010b20022001413f71418001723a000e20022001410c7641e001723a000c20022001410676413f71418001723a000d410321010b0240200041046a280200200041086a220428020022036b20014f0d00200020032001109980808000200428020021030b200028020020036a2002410c6a200110c5808080001a2004200320016a3602000b200241106a24808080800041000b180020002802002000280204200028020810a080808000000bbf0101027f23808080800041106b2203248080808000200041146a28020021040240024002400240200041046a2802000e020001030b20040d02419c81c080002100410021040c010b20040d01200028020022002802042104200028020021000b2003200436020420032000360200200341b882c08000200110be808080002002200110c08080800010aa80808000000b2003410036020420032000360200200341a482c08000200110be808080002002200110c08080800010aa80808000000b1c00024020000d00419c81c08000412b200110b880808000000b20000b2000024020000d00419c81c08000412b41f481c0800010b880808000000b20000b02000b2501017f2000200141002802f48bc080002202418b8080800020021b1181808080000000000b5901037f23808080800041106b2201248080808000200010bf8080800041e481c0800010a1808080002102200010be8080800010a28080800021032001200236020820012000360204200120033602002001109f80808000000bb10202047f017e23808080800041306b2202248080808000200141046a2103024020012802040d0020012802002104200241086a41086a22054100360200200242013703082002200241086a360214200241186a41106a200441106a290200370300200241186a41086a200441086a29020037030020022004290200370318200241146a41cc82c08000200241186a10ba808080001a200341086a2005280200360200200320022903083702000b200241186a41086a2204200341086a2802003602002001410c6a41003602002003290200210620014201370204200220063703180240410c410410828080800022010d00410c410410b180808000000b20012002290318370200200141086a20042802003602002000418482c0800036020420002001360200200241306a2480808080000bc80101037f23808080800041306b2202248080808000200141046a2103024020012802040d0020012802002101200241086a41086a22044100360200200242013703082002200241086a360214200241186a41106a200141106a290200370300200241186a41086a200141086a29020037030020022001290200370318200241146a41cc82c08000200241186a10ba808080001a200341086a2004280200360200200320022903083702000b2000418482c0800036020420002003360200200241306a2480808080000b4e01027f200128020421022001280200210302404108410410828080800022010d004108410410b180808000000b20012002360204200120033602002000419482c08000360204200020013602000b14002000419482c08000360204200020013602000bab0201037f23808080800041206b220524808080800041012106410041002802848cc08000220741016a3602848cc080000240024041002d00888cc08000450d0041002802908cc0800041016a21060c010b410041013a00888cc080000b410020063602908cc080000240024020074100480d00200641024b0d00200520043a0018200520033602142005200236021041002802f88bc080002207417f4c0d004100200741016a22073602f88bc08000024041002802808cc080002202450d0041002802fc8bc08000210720052000200128021011818080800000200520052903003703082007200541086a20022802141181808080000041002802f88bc0800021070b41002007417f6a3602f88bc08000200641014b0d0020040d010b00000b2000200110ab80808000000b3101017f23808080800041106b22022480808080002002200136020c20022000360208200241086a1095808080001a00000b5801027f02402000280200220341046a280200200341086a220428020022006b20024f0d00200320002002109980808000200428020021000b200328020020006a2001200210c5808080001a2004200020026a36020041000b120020002802002001109e808080001a41000b7401017f23808080800041206b220224808080800020022000280200360204200241086a41106a200141106a290200370300200241086a41086a200141086a29020037030020022001290200370308200241046a41cc82c08000200241086a10ba808080002101200241206a24808080800020010b0d002000200110b080808000000b0d0020002001108580808000000b0d002000200110b380808000000b4e01017f23808080800041206b22002480808080002000411c6a41003602002000418083c080003602182000420137020c2000419483c08000360208200041086a419c83c0800010b980808000000b0d002000200110af80808000000b0d002000200110a480808000000b0d0020002802001a037f0c000b0b02000bd80701067f20002802102103024002400240024002400240200028020822044101460d0020034101470d010b20034101470d03200120026a2105200041146a28020022060d0141002107200121080c020b2000280218200120022000411c6a28020028020c1182808080000021030c030b41002107200121080340200822032005460d020240024020032c00002208417f4c0d00200341016a21080c010b0240200841604f0d00200341026a21080c010b0240200841704f0d00200341036a21080c010b20032d0002413f7141067420032d0001413f71410c747220032d0003413f7172200841ff0171411274418080f0007172418080c400460d03200341046a21080b200720036b20086a21072006417f6a22060d000b0b20082005460d00024020082c00002203417f4a0d0020034160490d0020034170490d0020082d0002413f7141067420082d0001413f71410c747220082d0003413f7172200341ff0171411274418080f0007172418080c400460d010b02400240024020070d00410021080c010b024020072002490d00410021032002210820072002460d010c020b4100210320072108200120076a2c00004140480d010b20082107200121030b2007200220031b21022003200120031b21010b024020040d002000280218200120022000411c6a28020028020c118280808000000f0b2000410c6a28020021050240024020024110490d002001200210c38080800021080c010b024020020d00410021080c010b20024103712107024002402002417f6a41034f0d0041002108200121030c010b2002417c71210641002108200121030340200820032c000041bf7f4a6a200341016a2c000041bf7f4a6a200341026a2c000041bf7f4a6a200341036a2c000041bf7f4a6a2108200341046a21032006417c6a22060d000b0b2007450d000340200820032c000041bf7f4a6a2108200341016a21032007417f6a22070d000b0b0240200520084d0d0041002103200520086b22072106024002400240410020002d0020220820084103461b4103710e03020001020b41002106200721030c010b20074101762103200741016a41017621060b200341016a21032000411c6a28020021072000280204210820002802182100024003402003417f6a2203450d0120002008200728021011808080800000450d000b41010f0b410121032008418080c400460d01200020012002200728020c118280808000000d01410021030340024020062003470d0020062006490f0b200341016a210320002008200728021011808080800000450d000b2003417f6a2006490f0b2000280218200120022000411c6a28020028020c118280808000000f0b20030b5401017f23808080800041206b2203248080808000200341146a4100360200200341ac83c08000360210200342013702042003200136021c200320003602182003200341186a3602002003200210b980808000000b4c01017f23808080800041206b2202248080808000200241013a00182002200136021420022000360210200241bc83c0800036020c200241ac83c08000360208200241086a10a580808000000bbd05010a7f23808080800041306b2203248080808000200341246a2001360200200341033a0028200342808080808004370308200320003602204100210420034100360218200341003602100240024002400240200228020822050d00200241146a2802002206450d0120022802002101200228021021002006417f6a41ffffffff017141016a2204210603400240200141046a2802002207450d00200328022020012802002007200328022428020c118280808000000d040b2000280200200341086a200041046a280200118080808000000d03200041086a2100200141086a21012006417f6a22060d000c020b0b2002410c6a2802002200450d00200041057421082000417f6a41ffffff3f7141016a2104200228020021014100210603400240200141046a2802002200450d00200328022020012802002000200328022428020c118280808000000d030b2003200520066a2200411c6a2d00003a00282003200041046a290200422089370308200041186a28020021092002280210210a4100210b41002107024002400240200041146a2802000e03010002010b2009410374210c41002107200a200c6a220c280204419880808000470d01200c28020028020021090b410121070b2003200936021420032007360210200041106a28020021070240024002402000410c6a2802000e03010002010b20074103742109200a20096a2209280204419880808000470d01200928020028020021070b4101210b0b2003200736021c2003200b360218200a20002802004103746a2200280200200341086a2000280204118080808000000d02200141086a21012008200641206a2206470d000b0b4100210020042002280204492201450d012003280220200228020020044103746a410020011b22012802002001280204200328022428020c11828080800000450d010b410121000b200341306a24808080800020000b0c004281b8aa93f5f3e5ec140b2100200128021841ac83c08000410e2001411c6a28020028020c118280808000000b140020012000280200200028020410b7808080000b070020002802080b0700200028020c0b070020002d00100b180020002802002001200028020428020c118080808000000b930101017f23808080800041c0006b22052480808080002005200136020c2005200036020820052003360214200520023602102005412c6a41023602002005413c6a4199808080003602002005420237021c200541d083c080003602182005419a808080003602342005200541306a3602282005200541106a3602382005200541086a360230200541186a200410b980808000000ba30801097f02400240200041036a417c71220220006b220320014b0d00200341044b0d00200120036b22044104490d0020044103712105410021064100210102402003450d00200341037121070240024020022000417f736a41034f0d0041002101200021020c010b2003417c71210841002101200021020340200120022c000041bf7f4a6a200241016a2c000041bf7f4a6a200241026a2c000041bf7f4a6a200241036a2c000041bf7f4a6a2101200241046a21022008417c6a22080d000b0b2007450d000340200120022c000041bf7f4a6a2101200241016a21022007417f6a22070d000b0b200020036a210002402005450d0020002004417c716a22022c000041bf7f4a210620054101460d00200620022c000141bf7f4a6a210620054102460d00200620022c000241bf7f4a6a21060b20044102762103200620016a21080340200021062003450d02200341c001200341c001491b220441037121052004410274210902400240200441fc0171220a41027422000d00410021020c010b200620006a2107410021022006210003402000410c6a2802002201417f73410776200141067672418182840871200041086a2802002201417f73410776200141067672418182840871200041046a2802002201417f7341077620014106767241818284087120002802002201417f7341077620014106767241818284087120026a6a6a6a2102200041106a22002007470d000b0b200620096a2100200320046b2103200241087641ff81fc0771200241ff81fc07716a418180046c41107620086a21082005450d000b2006200a4102746a2100200541ffffffff036a220441ffffffff0371220241016a2201410371210302400240200241034f0d00410021020c010b200141fcffffff077121014100210203402000410c6a2802002207417f73410776200741067672418182840871200041086a2802002207417f73410776200741067672418182840871200041046a2802002207417f7341077620074106767241818284087120002802002207417f7341077620074106767241818284087120026a6a6a6a2102200041106a21002001417c6a22010d000b0b02402003450d00200441818080807c6a2101034020002802002207417f7341077620074106767241818284087120026a2102200041046a21002001417f6a22010d000b0b200241087641ff81fc0771200241ff81fc07716a418180046c41107620086a0f0b024020010d0041000f0b20014103712102024002402001417f6a41034f0d00410021080c010b2001417c712101410021080340200820002c000041bf7f4a6a200041016a2c000041bf7f4a6a200041026a2c000041bf7f4a6a200041036a2c000041bf7f4a6a2108200041046a21002001417c6a22010d000b0b2002450d000340200820002c000041bf7f4a6a2108200041016a21002002417f6a22020d000b0b20080bc10201087f024002402002410f4b0d00200021030c010b2000410020006b41037122046a210502402004450d0020002103200121060340200320062d00003a0000200641016a2106200341016a22032005490d000b0b2005200220046b2207417c7122086a210302400240200120046a2209410371450d0020084101480d012009410374220641187121022009417c71220a41046a2101410020066b4118712104200a28020021060340200520062002762001280200220620047472360200200141046a2101200541046a22052003490d000c020b0b20084101480d0020092101034020052001280200360200200141046a2101200541046a22052003490d000b0b20074103712102200920086a21010b02402002450d00200320026a21050340200320012d00003a0000200141016a2101200341016a22032005490d000b0b20000b0e0020002001200210c4808080000b0bea030100418080c0000be0032f7573722f7372632f6b65726e656c5f656e7472792f7372632f63616368652e7273000000001000220000001300000020000000616c726561647920626f72726f776564010000000000000001000000020000000300000000000000010000000400000005000000060000000300000004000000040000000700000008000000090000000a000000000000000100000004000000050000000600000063616c6c656420604f7074696f6e3a3a756e77726170282960206f6e206120604e6f6e65602076616c75656c6962726172792f7374642f7372632f70616e69636b696e672e727300c70010001c000000460200001f000000c70010001c000000470200001e0000000c0000000c000000040000000d0000000e00000008000000040000000f00000010000000100000000400000011000000120000000e000000080000000400000013000000140000000e00000004000000040000001500000016000000170000006c6962726172792f616c6c6f632f7372632f7261775f7665632e72736361706163697479206f766572666c6f770000008001100011000000640110001c0000000602000005000000426f72726f774d75744572726f7200001b00000000000000010000001c0000003a200000ac01100000000000cc01100002000000"


let test_rollup_node_advances_pvm_state protocols ~kind =
  let go ~internal client sc_rollup sc_rollup_node =
    let* genesis_info =
      RPC.Client.call ~hooks client
      @@ RPC.get_chain_block_context_sc_rollup_genesis_info sc_rollup
    in
    let init_level = JSON.(genesis_info |-> "level" |> as_int) in

    let* () = Sc_rollup_node.run sc_rollup_node in
    let sc_rollup_client = Sc_rollup_client.create sc_rollup_node in

    let* level =
      Sc_rollup_node.wait_for_level ~timeout:3. sc_rollup_node init_level
    in
    Check.(level = init_level)
      Check.int
      ~error_msg:"Current level has moved past origination level (%L = %R)" ;
    let* level, forwarder =
      if not internal then return (level, None)
      else
        (* Originate forwarder contract to send internal messages to rollup *)
        let* contract_id =
          Client.originate_contract
            ~alias:"rollup_deposit"
            ~amount:Tez.zero
            ~src:Constant.bootstrap1.alias
            ~prg:"file:./tezt/tests/contracts/proto_alpha/sc_rollup_forward.tz"
            ~init:"Unit"
            ~burn_cap:Tez.(of_int 1)
            client
        in
        let* () = Client.bake_for_and_wait client in
        Log.info
          "The forwarder %s contract was successfully originated"
          contract_id ;
        return (level + 1, Some contract_id)
    in
    (* Called with monotonically increasing [i] *)
    let test_message i =
      let* prev_state_hash =
        Sc_rollup_client.state_hash ~hooks sc_rollup_client
      in
      (* let* prev_ticks = Sc_rollup_client.total_ticks ~hooks sc_rollup_client in *)
      (* TODO Wasm PVM needs different messages
         Note [sf = Printf.sprintf]
      *)
      let message = sf "%d %d + value" i ((i + 2) * 2) in
      let* () =
        match forwarder with
        | None ->
            (* External message *)
            send_message client sc_rollup (sf "[%S]" message)
        | Some forwarder ->
            (* Internal message through forwarder *)
            let* () =
              Client.transfer
                client
                ~amount:Tez.zero
                ~giver:Constant.bootstrap1.alias
                ~receiver:forwarder
                ~arg:(sf "Pair %S %S" sc_rollup message)
            in
            Client.bake_for_and_wait client
      in
      let* _ =
        Sc_rollup_node.wait_for_level
          (* ~timeout:3. *) sc_rollup_node
          (level + i)
      in

      (* specific per kind PVM checks *)
      let* () =
        match kind with
        | "arith" ->
            let* encoded_value =
              Sc_rollup_client.state_value
                ~hooks
                sc_rollup_client
                ~key:"vars/value"
            in
            let value =
              match Data_encoding.(Binary.of_bytes int31) @@ encoded_value with
              | Error error ->
                  failwith
                    (Format.asprintf
                       "The arithmetic PVM has an unexpected state: %a"
                       Data_encoding.Binary.pp_read_error
                       error)
              | Ok x -> x
            in
            Check.(
              (value = i + ((i + 2) * 2))
                int
                ~error_msg:"Invalid value in rollup state (%L <> %R)") ;
            return ()
        | "wasm_2_0_0" -> return ()
        | _otherwise -> raise (Invalid_argument kind)
      in

      let* state_hash = Sc_rollup_client.state_hash ~hooks sc_rollup_client in
      Check.(state_hash <> prev_state_hash)
        Check.string
        ~error_msg:"State hash has not changed (%L <> %R)" ;

      (* let* ticks = Sc_rollup_client.total_ticks ~hooks sc_rollup_client in *)
      (* Check.(ticks >= prev_ticks) *)
      (*   Check.int *)
      (*   ~error_msg:"Tick counter did not advance (%L >= %R)" ; *)
      Lwt.return_unit
    in
    let* () = Lwt_list.iter_s test_message (range 1 10) in

    Lwt.return_unit
  in

  (* DEMO *)
  regression_test
    ~__FILE__
    ~tags:["sc_rollup"; "run"; "node"; kind]
    (Format.asprintf "%s - node advances PVM state with messages" kind)
    (fun protocol ->
      setup ~protocol @@ fun node client ->
      with_fresh_rollup
        ~kind
        ~boot_sector:(computation_kernel ())
        (fun sc_rollup_address sc_rollup_node _filename ->
          go ~internal:false client sc_rollup_address sc_rollup_node)
        node
        client)
    protocols ;

  regression_test
    ~__FILE__
    ~tags:["sc_rollup"; "run"; "node"; "internal"; kind]
    (Format.asprintf "%s - node advances PVM state with internal messages" kind)
    (fun protocol ->
      setup ~protocol @@ fun node client ->
      with_fresh_rollup
        ~kind
        (fun sc_rollup_address sc_rollup_node _filename ->
          go ~internal:true client sc_rollup_address sc_rollup_node)
        node
        client)
    protocols

(* Ensure that commitments are stored and published properly.
   ----------------------------------------------------------

   Every 20 level, a commitment is computed and stored by the
   rollup node. The rollup node will also publish previously
   computed commitments on the layer1, in a first in first out
   fashion. To ensure that commitments are robust to chain
   reorganisations, only finalized block are processed when
   trying to publish a commitment.
*)

let bake_levels ?hook n client =
  fold n () @@ fun i () ->
  let* () = match hook with None -> return () | Some hook -> hook i in
  Client.bake_for_and_wait client

let eq_commitment_typ =
  Check.equalable
    (fun ppf (c : Sc_rollup_client.commitment) ->
      Format.fprintf
        ppf
        "@[<hov 2>{ predecessor: %s,@,\
         state: %s,@,\
         inbox level: %d,@,\
         ticks: %d }@]"
        c.predecessor
        c.compressed_state
        c.inbox_level
        c.number_of_ticks)
    ( = )

let check_commitment_eq (commitment, name) (expected_commitment, exp_name) =
  Check.((commitment = expected_commitment) (option eq_commitment_typ))
    ~error_msg:
      (sf
         "Commitment %s differs from the one %s.\n%s: %%L\n%s: %%R"
         name
         exp_name
         (String.capitalize_ascii name)
         (String.capitalize_ascii exp_name))

let tezos_client_get_commitment client sc_rollup commitment_hash =
  let* output =
    Client.rpc
      Client.GET
      [
        "chains";
        "main";
        "blocks";
        "head";
        "context";
        "sc_rollup";
        sc_rollup;
        "commitment";
        commitment_hash;
      ]
      client
  in
  Lwt.return @@ Sc_rollup_client.commitment_from_json output

let check_published_commitment_in_l1 ?(allow_non_published = false)
    ?(force_new_level = true) sc_rollup client published_commitment =
  let* () =
    if force_new_level then
      (* Triggers injection into the L1 context *)
      bake_levels 1 client
    else Lwt.return_unit
  in
  let* commitment_in_l1 =
    match published_commitment with
    | None ->
        if not allow_non_published then
          Test.fail "No commitment has been published" ;
        Lwt.return_none
    | Some (hash, _commitment, _level) ->
        tezos_client_get_commitment client sc_rollup hash
  in
  let published_commitment =
    Option.map (fun (_, c, _) -> c) published_commitment
  in
  check_commitment_eq
    (commitment_in_l1, "in L1")
    (published_commitment, "published") ;
  Lwt.return_unit

let test_commitment_scenario ?commitment_period ?challenge_window
    ?(extra_tags = []) variant =
  test_scenario
    ?commitment_period
    ?challenge_window
    {
      tags = ["commitment"; "node"] @ extra_tags;
      variant;
      description = "rollup node - correct handling of commitments";
    }

let commitment_stored _protocol sc_rollup_node sc_rollup _node client =
  (* The rollup is originated at level `init_level`, and it requires
     `sc_rollup_commitment_period_in_blocks` levels to store a commitment.
     There is also a delay of `block_finality_time` before storing a
     commitment, to avoid including wrong commitments due to chain
     reorganisations. Therefore the commitment will be stored and published
     when the [Commitment] module processes the block at level
     `init_level + sc_rollup_commitment_period_in_blocks +
     levels_to_finalise`.
  *)
  let* genesis_info =
    RPC.Client.call ~hooks client
    @@ RPC.get_chain_block_context_sc_rollup_genesis_info sc_rollup
  in
  let init_level = JSON.(genesis_info |-> "level" |> as_int) in

  let* levels_to_commitment =
    get_sc_rollup_commitment_period_in_blocks client
  in
  let store_commitment_level =
    init_level + levels_to_commitment + block_finality_time
  in
  let* () = Sc_rollup_node.run sc_rollup_node in
  let sc_rollup_client = Sc_rollup_client.create sc_rollup_node in
  let* level =
    Sc_rollup_node.wait_for_level ~timeout:3. sc_rollup_node init_level
  in
  Check.(level = init_level)
    Check.int
    ~error_msg:"Current level has moved past origination level (%L = %R)" ;
  let* () =
    (* at init_level + i we publish i messages, therefore at level
       init_level + i a total of 1+..+i = (i*(i+1))/2 messages will have been
       sent.
    *)
    send_messages levels_to_commitment sc_rollup client
  in
  let* _ =
    Sc_rollup_node.wait_for_level
      ~timeout:3.
      sc_rollup_node
      (init_level + levels_to_commitment)
  in
  (* Bake [block_finality_time] additional levels to ensure that block number
     [init_level + sc_rollup_commitment_period_in_blocks] is
     processed by the rollup node as finalized. *)
  let* () = bake_levels block_finality_time client in
  let* _ =
    Sc_rollup_node.wait_for_level
      ~timeout:3.
      sc_rollup_node
      store_commitment_level
  in
  let* stored_commitment =
    Sc_rollup_client.last_stored_commitment ~hooks sc_rollup_client
  in
  let stored_inbox_level = Option.map inbox_level stored_commitment in
  Check.(stored_inbox_level = Some (levels_to_commitment + init_level))
    (Check.option Check.int)
    ~error_msg:
      "Commitment has been stored at a level different than expected (%L = %R)" ;
  (* Bake one level for commitment to be included *)
  let* () = Client.bake_for_and_wait client in
  let* published_commitment =
    Sc_rollup_client.last_published_commitment ~hooks sc_rollup_client
  in
  check_commitment_eq
    (Option.map (fun (_, c, _) -> c) stored_commitment, "stored")
    (Option.map (fun (_, c, _) -> c) published_commitment, "published") ;
  check_published_commitment_in_l1 sc_rollup client published_commitment

let mode_publish mode publishes protocol sc_rollup_node sc_rollup node client =
  setup ~protocol @@ fun other_node other_client _ ->
  let* () = Client.Admin.trust_address client ~peer:other_node
  and* () = Client.Admin.trust_address other_client ~peer:node in
  let* () = Client.Admin.connect_address client ~peer:other_node in
  let* () = Sc_rollup_node.run sc_rollup_node in
  let sc_rollup_client = Sc_rollup_client.create sc_rollup_node in
  let level = Node.get_level node in
  let* levels_to_commitment =
    get_sc_rollup_commitment_period_in_blocks client
  in
  let* () = send_messages levels_to_commitment sc_rollup client in
  let* level =
    Sc_rollup_node.wait_for_level sc_rollup_node (level + levels_to_commitment)
  in
  Log.info "Starting other rollup node." ;
  let purposes = ["publish"; "cement"; "add_messages"] in
  let operators =
    List.mapi
      (fun i purpose ->
        (purpose, Constant.[|bootstrap3; bootstrap5; bootstrap4|].(i).alias))
      purposes
  in
  let sc_rollup_other_node =
    (* Other rollup node *)
    Sc_rollup_node.create
      mode
      other_node
      other_client
      ~operators
      ~default_operator:Constant.bootstrap3.alias
  in
  let sc_rollup_other_client = Sc_rollup_client.create sc_rollup_other_node in
  let* _configuration_filename =
    Sc_rollup_node.config_init sc_rollup_other_node sc_rollup
  in
  let* () = Sc_rollup_node.run sc_rollup_other_node in
  let* _level = Sc_rollup_node.wait_for_level sc_rollup_other_node level in
  Log.info "Other rollup node synchronized." ;
  let* () = send_messages levels_to_commitment sc_rollup client in
  let* level =
    Sc_rollup_node.wait_for_level sc_rollup_node (level + levels_to_commitment)
  in
  let* _ = Sc_rollup_node.wait_for_level sc_rollup_node level
  and* _ = Sc_rollup_node.wait_for_level sc_rollup_other_node level in
  Log.info "Both rollup nodes have reached level %d." level ;
  let* state_hash = Sc_rollup_client.state_hash sc_rollup_client
  and* state_hash_other = Sc_rollup_client.state_hash sc_rollup_other_client in
  Check.((state_hash = state_hash_other) string)
    ~error_msg:
      "State hash of other rollup node is %R but the first rollup node has %L" ;
  let* published_commitment =
    Sc_rollup_client.last_published_commitment ~hooks sc_rollup_client
  in
  let* other_published_commitment =
    Sc_rollup_client.last_published_commitment ~hooks sc_rollup_other_client
  in
  if published_commitment = None then
    Test.fail "Operator has not published a commitment but should have." ;
  if other_published_commitment = None = publishes then
    Test.fail
      "Other has%s published a commitment but should%s."
      (if publishes then " not" else "")
      (if publishes then " have" else " never do so") ;
  unit

let commitment_not_stored_if_non_final _protocol sc_rollup_node sc_rollup _node
    client =
  (* The rollup is originated at level `init_level`, and it requires
     `sc_rollup_commitment_period_in_blocks` levels to store a commitment.
     There is also a delay of `block_finality_time` before storing a
     commitment, to avoid including wrong commitments due to chain
     reorganisations. Therefore the commitment will be stored and published
     when the [Commitment] module processes the block at level
     `init_level + sc_rollup_commitment_period_in_blocks +
     levels_to_finalise`. At the level before, the commitment will not be
     neither stored nor published.
  *)
  let* genesis_info =
    RPC.Client.call ~hooks client
    @@ RPC.get_chain_block_context_sc_rollup_genesis_info sc_rollup
  in
  let init_level = JSON.(genesis_info |-> "level" |> as_int) in

  let* levels_to_commitment =
    get_sc_rollup_commitment_period_in_blocks client
  in
  let levels_to_finalize = block_finality_time - 1 in
  let store_commitment_level = init_level + levels_to_commitment in
  let* () = Sc_rollup_node.run sc_rollup_node in
  let sc_rollup_client = Sc_rollup_client.create sc_rollup_node in
  let* level =
    Sc_rollup_node.wait_for_level ~timeout:3. sc_rollup_node init_level
  in
  Check.(level = init_level)
    Check.int
    ~error_msg:"Current level has moved past origination level (%L = %R)" ;
  let* () = send_messages levels_to_commitment sc_rollup client in
  let* _ =
    Sc_rollup_node.wait_for_level
      ~timeout:3.
      sc_rollup_node
      store_commitment_level
  in
  let* () = bake_levels levels_to_finalize client in
  let* _ =
    Sc_rollup_node.wait_for_level
      ~timeout:3.
      sc_rollup_node
      (store_commitment_level + levels_to_finalize)
  in
  let* commitment =
    Sc_rollup_client.last_stored_commitment ~hooks sc_rollup_client
  in
  let stored_inbox_level = Option.map inbox_level commitment in
  Check.(stored_inbox_level = None)
    (Check.option Check.int)
    ~error_msg:
      "Commitment has been stored at a level different than expected (%L = %R)" ;
  let* commitment =
    Sc_rollup_client.last_published_commitment ~hooks sc_rollup_client
  in
  let published_inbox_level = Option.map inbox_level commitment in
  Check.(published_inbox_level = None)
    (Check.option Check.int)
    ~error_msg:
      "Commitment has been published at a level different than expected (%L = \
       %R)" ;
  Lwt.return_unit

let commitments_messages_reset _protocol sc_rollup_node sc_rollup _node client =
  (* For `sc_rollup_commitment_period_in_blocks` levels after the sc rollup
     origination, i messages are sent to the rollup, for a total of
     `sc_rollup_commitment_period_in_blocks *
     (sc_rollup_commitment_period_in_blocks + 1)/2` messages. These will be
     the number of messages in the first commitment published by the rollup
     node. Then, for other `sc_rollup_commitment_period_in_blocks` levels,
     no messages are sent to the sc-rollup address. The second commitment
     published by the sc-rollup node will contain 0 messages. Finally,
     `block_finality_time` empty levels are baked which ensures that two
     commitments are stored and published by the rollup node.
  *)
  let* genesis_info =
    RPC.Client.call ~hooks client
    @@ RPC.get_chain_block_context_sc_rollup_genesis_info sc_rollup
  in
  let init_level = JSON.(genesis_info |-> "level" |> as_int) in

  let* levels_to_commitment =
    get_sc_rollup_commitment_period_in_blocks client
  in
  let* () = Sc_rollup_node.run sc_rollup_node in
  let sc_rollup_client = Sc_rollup_client.create sc_rollup_node in
  let* level =
    Sc_rollup_node.wait_for_level ~timeout:3. sc_rollup_node init_level
  in
  Check.(level = init_level)
    Check.int
    ~error_msg:"Current level has moved past origination level (%L = %R)" ;
  let* () =
    (* At init_level + i we publish i messages, therefore at level
       init_level + 20 a total of 1+..+20 = (20*21)/2 = 210 messages
       will have been sent.
    *)
    send_messages levels_to_commitment sc_rollup client
  in
  (* Bake other `sc_rollup_commitment_period_in_blocks +
     block_finality_time` levels with no messages. The first
     `sc_rollup_commitment_period_in_blocks` levels contribute to the second
     commitment stored by the rollup node. The last `block_finality_time`
     levels ensure that the second commitment is stored and published by the
     rollup node.
  *)
  let* () = bake_levels (levels_to_commitment + block_finality_time) client in
  let* _ =
    Sc_rollup_node.wait_for_level
      ~timeout:3.
      sc_rollup_node
      (init_level + (2 * levels_to_commitment) + block_finality_time)
  in
  let* stored_commitment =
    Sc_rollup_client.last_stored_commitment ~hooks sc_rollup_client
  in
  let stored_inbox_level = Option.map inbox_level stored_commitment in
  Check.(stored_inbox_level = Some (init_level + (2 * levels_to_commitment)))
    (Check.option Check.int)
    ~error_msg:
      "Commitment has been stored at a level different than expected (%L = %R)" ;
  (let stored_number_of_ticks = Option.map number_of_ticks stored_commitment in
   Check.(stored_number_of_ticks = Some 0)
     (Check.option Check.int)
     ~error_msg:
       "Number of messages processed by commitment is different from the \
        number of messages expected (%L = %R)") ;
  let* published_commitment =
    Sc_rollup_client.last_published_commitment ~hooks sc_rollup_client
  in
  check_commitment_eq
    (Option.map (fun (_, c, _) -> c) stored_commitment, "stored")
    (Option.map (fun (_, c, _) -> c) published_commitment, "published") ;
  check_published_commitment_in_l1 sc_rollup client published_commitment

let commitment_stored_robust_to_failures _protocol sc_rollup_node sc_rollup node
    client =
  (* This test uses two rollup nodes for the same rollup, tracking the same L1 node.
     Both nodes process heads from the L1. However, the second node is stopped
     one level before publishing a commitment, and then is restarted.
     We should not observe any difference in the commitments stored by the
     two rollup nodes.
  *)
  let* genesis_info =
    RPC.Client.call ~hooks client
    @@ RPC.get_chain_block_context_sc_rollup_genesis_info sc_rollup
  in
  let init_level = JSON.(genesis_info |-> "level" |> as_int) in

  let* levels_to_commitment =
    get_sc_rollup_commitment_period_in_blocks client
  in
  let bootstrap2_key = Constant.bootstrap2.public_key_hash in
  let* client' = Client.init ?endpoint:(Some (Node node)) () in
  let sc_rollup_node' =
    Sc_rollup_node.create Operator node client' ~default_operator:bootstrap2_key
  in
  let* _configuration_filename =
    Sc_rollup_node.config_init sc_rollup_node' sc_rollup
  in
  let sc_rollup_client = Sc_rollup_client.create sc_rollup_node in
  let sc_rollup_client' = Sc_rollup_client.create sc_rollup_node' in
  let* () = Sc_rollup_node.run sc_rollup_node in
  let* () = Sc_rollup_node.run sc_rollup_node' in
  let* level =
    Sc_rollup_node.wait_for_level ~timeout:3. sc_rollup_node init_level
  in
  Check.(level = init_level)
    Check.int
    ~error_msg:"Current level has moved past origination level (%L = %R)" ;
  let* () =
    (* at init_level + i we publish i messages, therefore at level
       init_level + i a total of 1+..+i = (i*(i+1))/2 messages will have been
       sent.
    *)
    send_messages levels_to_commitment sc_rollup client
  in
  (* The line below works as long as we have a block finality time which is strictly positive,
     which is a safe assumption. *)
  let* () = bake_levels (block_finality_time - 1) client in
  let* level_before_storing_commitment =
    Sc_rollup_node.wait_for_level
      ~timeout:3.
      sc_rollup_node
      (init_level + levels_to_commitment + block_finality_time - 1)
  in
  let* _ =
    Sc_rollup_node.wait_for_level
      ~timeout:3.
      sc_rollup_node'
      level_before_storing_commitment
  in
  let* () = Sc_rollup_node.terminate sc_rollup_node' in
  let* () = Sc_rollup_node.run sc_rollup_node' in
  let* () = Client.bake_for_and_wait client in
  let* () = Sc_rollup_node.terminate sc_rollup_node' in
  let* () = Client.bake_for_and_wait client in
  let* () = Sc_rollup_node.run sc_rollup_node' in
  let* level_commitment_is_stored =
    Sc_rollup_node.wait_for_level
      ~timeout:3.
      sc_rollup_node
      (level_before_storing_commitment + 1)
  in
  let* _ =
    Sc_rollup_node.wait_for_level
      ~timeout:3.
      sc_rollup_node'
      level_commitment_is_stored
  in
  let* stored_commitment =
    Sc_rollup_client.last_stored_commitment ~hooks sc_rollup_client
  in
  let* stored_commitment' =
    Sc_rollup_client.last_stored_commitment ~hooks sc_rollup_client'
  in
  check_commitment_eq
    (Option.map (fun (_, c, _) -> c) stored_commitment, "stored in first node")
    (Option.map (fun (_, c, _) -> c) stored_commitment', "stored in second node") ;
  return ()

let commitments_reorgs protocol sc_rollup_node sc_rollup node client =
  (* No messages are published after origination, for
     `sc_rollup_commitment_period_in_blocks - 1` levels. Then a divergence
     occurs:  in the first branch one message is published for
     `block_finality_time - 1` blocks. In the second branch no messages are
     published for `block_finality_time` blocks. The second branch is
     the more attractive one, and will be chosen when a reorganisation occurs.
     One more level is baked to ensure that the rollup node stores and
     publishes the commitment. The final commitment should have
     no messages and no ticks.
  *)
  let* genesis_info =
    RPC.Client.call ~hooks client
    @@ RPC.get_chain_block_context_sc_rollup_genesis_info sc_rollup
  in
  let init_level = JSON.(genesis_info |-> "level" |> as_int) in

  let* levels_to_commitment =
    get_sc_rollup_commitment_period_in_blocks client
  in
  let num_empty_blocks = block_finality_time in
  let num_messages = 1 in
  let sc_rollup_client = Sc_rollup_client.create sc_rollup_node in

  setup ~protocol @@ fun node' client' _ ->
  let* () = Client.Admin.trust_address client ~peer:node'
  and* () = Client.Admin.trust_address client' ~peer:node in
  let* () = Client.Admin.connect_address client ~peer:node' in

  let* () = Sc_rollup_node.run sc_rollup_node in
  (* We bake `sc_rollup_commitment_period_in_blocks - 1` levels, which
     should cause both nodes to observe level
     `sc_rollup_commitment_period_in_blocks + init_level - 1 . *)
  let* () = bake_levels (levels_to_commitment - 1) client in
  let* _ = Node.wait_for_level node (init_level + levels_to_commitment - 1) in
  let* _ = Node.wait_for_level node' (init_level + levels_to_commitment - 1) in
  let* _ =
    Sc_rollup_node.wait_for_level
      ~timeout:3.
      sc_rollup_node
      (init_level + levels_to_commitment - 1)
  in
  Log.info "Nodes are synchronized." ;

  let divergence () =
    let* identity' = Node.wait_for_identity node' in
    let* () = Client.Admin.kick_peer client ~peer:identity' in
    let* () = send_messages num_messages sc_rollup client in
    (* `block_finality_time - 1` blocks with message for [node] *)
    let* _ =
      Node.wait_for_level
        node
        (init_level + levels_to_commitment - 1 + num_messages)
    in

    let* () = bake_levels num_empty_blocks client' in
    (* `block_finality_time` blocks with no messages for [node'] *)
    let* _ =
      Node.wait_for_level
        node'
        (init_level + levels_to_commitment - 1 + num_empty_blocks)
    in
    Log.info "Nodes are following distinct branches." ;
    return ()
  in

  let trigger_reorg () =
    let* () = Client.Admin.connect_address client ~peer:node' in
    let* _ =
      Node.wait_for_level
        node
        (init_level + levels_to_commitment - 1 + num_empty_blocks)
    in
    Log.info "Nodes are synchronized again." ;
    return ()
  in

  let* () = divergence () in
  let* () = trigger_reorg () in
  (* After triggering a reorganisation the node should see that there is a more
     attractive head at level `init_level +
     sc_rollup_commitment_period_in_blocks + block_finality_time - 1`.
  *)
  let* _ =
    Sc_rollup_node.wait_for_level
      ~timeout:3.
      sc_rollup_node
      (init_level + levels_to_commitment - 1 + num_empty_blocks)
  in
  (* exactly one level left to finalize the commitment in the node. *)
  let* () = bake_levels (block_finality_time - num_empty_blocks + 1) client in
  let* _ =
    Sc_rollup_node.wait_for_level
      ~timeout:3.
      sc_rollup_node
      (init_level + levels_to_commitment + block_finality_time)
  in
  let* stored_commitment =
    Sc_rollup_client.last_stored_commitment ~hooks sc_rollup_client
  in
  let stored_inbox_level = Option.map inbox_level stored_commitment in
  Check.(stored_inbox_level = Some (init_level + levels_to_commitment))
    (Check.option Check.int)
    ~error_msg:
      "Commitment has been stored at a level different than expected (%L = %R)" ;
  (let stored_number_of_ticks = Option.map number_of_ticks stored_commitment in
   Check.(stored_number_of_ticks = Some 0)
     (Check.option Check.int)
     ~error_msg:
       "Number of messages processed by commitment is different from the \
        number of messages expected (%L = %R)") ;
  let* published_commitment =
    Sc_rollup_client.last_published_commitment ~hooks sc_rollup_client
  in
  check_commitment_eq
    (Option.map (fun (_, c, _) -> c) stored_commitment, "stored")
    (Option.map (fun (_, c, _) -> c) published_commitment, "published") ;
  check_published_commitment_in_l1 sc_rollup client published_commitment

type balances = {liquid : int; frozen : int}

let contract_balances ~pkh client =
  let*! liquid = RPC.Contracts.get_balance ~contract_id:pkh client in
  let*! frozen = RPC.Contracts.get_frozen_bonds ~contract_id:pkh client in
  return {liquid = JSON.as_int liquid; frozen = JSON.as_int frozen}

(** This helper allow to attempt recovering bond for SCORU rollup operator.
    if [expect_failure] is set to some string then, we expect the command to fail
    with an error that contains that string. *)
let attempt_withdraw_stake =
  let check_eq_int a b =
    Check.((a = b) int ~error_msg:"expected value %L, got %R")
  in
  fun ?expect_failure ~sc_rollup client ->
    (* placehoders *)
    (* TODO/Fixme:
        - Shoud provide the rollup operator key (bootstrap1_key) as an
          argument to scenarios.
    *)
    let bootstrap1_key = Constant.bootstrap1.public_key_hash in
    let* constants = RPC.get_constants ~hooks client in
    let recover_bond_unfreeze =
      JSON.(constants |-> "sc_rollup_stake_amount" |> as_int)
    in
    let recover_bond_fee = 1_000_000 in
    let inject_op () =
      Client.Sc_rollup.submit_recover_bond
        ~hooks
        ~rollup:sc_rollup
        ~src:bootstrap1_key
        ~fee:(Tez.of_mutez_int recover_bond_fee)
        client
    in
    match expect_failure with
    | None ->
        let*! () = inject_op () in
        let* old_bal = contract_balances ~pkh:bootstrap1_key client in
        let* () = Client.bake_for_and_wait ~keys:["bootstrap2"] client in
        let* new_bal = contract_balances ~pkh:bootstrap1_key client in
        let expected_liq_new_bal =
          old_bal.liquid - recover_bond_fee + recover_bond_unfreeze
        in
        check_eq_int new_bal.liquid expected_liq_new_bal ;
        check_eq_int new_bal.frozen (old_bal.frozen - recover_bond_unfreeze) ;
        unit
    | Some failure_string ->
        let*? p = inject_op () in
        Process.check_error ~msg:(rex failure_string) p

(* FIXME: https://gitlab.com/tezos/tezos/-/issues/2942
   Do not pass an explicit value for `?commitment_period until
   https://gitlab.com/tezos/tezos/-/merge_requests/5212 has been merged. *)
(* Test that nodes do not publish commitments before the last cemented commitment. *)
let commitment_before_lcc_not_published _protocol sc_rollup_node sc_rollup node
    client =
  let* constants = get_sc_rollup_constants client in
  let commitment_period = constants.commitment_period_in_blocks in
  let challenge_window = constants.challenge_window_in_blocks in
  (* Rollup node 1 processes messages, produces and publishes two commitments. *)
  let* genesis_info =
    RPC.Client.call ~hooks client
    @@ RPC.get_chain_block_context_sc_rollup_genesis_info sc_rollup
  in
  let init_level = JSON.(genesis_info |-> "level" |> as_int) in

  let* () = Sc_rollup_node.run sc_rollup_node in
  let sc_rollup_client = Sc_rollup_client.create sc_rollup_node in
  let* level =
    Sc_rollup_node.wait_for_level ~timeout:3. sc_rollup_node init_level
  in
  Check.(level = init_level)
    Check.int
    ~error_msg:"Current level has moved past origination level (%L = %R)" ;
  let* () = bake_levels commitment_period client in
  let* commitment_inbox_level =
    Sc_rollup_node.wait_for_level
      ~timeout:3.
      sc_rollup_node
      (init_level + commitment_period)
  in
  (* Bake `block_finality_time` additional level to ensure that block number
     `init_level + sc_rollup_commitment_period_in_blocks` is processed by
     the rollup node as finalized. *)
  let* () = bake_levels block_finality_time client in
  let* commitment_finalized_level =
    Sc_rollup_node.wait_for_level
      ~timeout:3.
      sc_rollup_node
      (commitment_inbox_level + block_finality_time)
  in
  let* rollup_node1_stored_commitment =
    Sc_rollup_client.last_stored_commitment ~hooks sc_rollup_client
  in
  let* rollup_node1_published_commitment =
    Sc_rollup_client.last_published_commitment ~hooks sc_rollup_client
  in
  let () =
    Check.(
      Option.map inbox_level rollup_node1_published_commitment
      = Some commitment_inbox_level)
      (Check.option Check.int)
      ~error_msg:
        "Commitment has been published at a level different than expected (%L \
         = %R)"
  in
  (* Cement commitment manually: the commitment can be cemented after
     `challenge_window_levels` have passed since the commitment was published
     (that is at level `commitment_finalized_level`). Note that at this point
     we are already at level `commitment_finalized_level`, hence cementation of
     the commitment can happen. *)
  let levels_to_cementation = challenge_window + 1 in
  let cemented_commitment_hash =
    Option.map hash rollup_node1_published_commitment
    |> Option.value
         ~default:"scc12XhSULdV8bAav21e99VYLTpqAjTd7NU8Mn4zFdKPSA8auMbggG"
  in
  let* () = bake_levels levels_to_cementation client in
  let* cemented_commitment_level =
    Sc_rollup_node.wait_for_level
      ~timeout:3.
      sc_rollup_node
      (commitment_finalized_level + levels_to_cementation)
  in

  (* Withdraw stake before cementing should fail *)
  let* () =
    attempt_withdraw_stake
      ~sc_rollup
      client
      ~expect_failure:
        "Attempted to withdraw while not staked on the last cemented \
         commitment."
  in

  let* () =
    cement_commitment client ~sc_rollup ~hash:cemented_commitment_hash
  in
  let* level_after_cementation =
    Sc_rollup_node.wait_for_level
      ~timeout:3.
      sc_rollup_node
      (cemented_commitment_level + 1)
  in

  (* Withdraw stake after cementing should succeed *)
  let* () = attempt_withdraw_stake ~sc_rollup client in

  let* () = Sc_rollup_node.terminate sc_rollup_node in
  (* Rollup node 2 starts and processes enough levels to publish a commitment.*)
  let bootstrap2_key = Constant.bootstrap2.public_key_hash in
  let* client' = Client.init ?endpoint:(Some (Node node)) () in
  let sc_rollup_node' =
    Sc_rollup_node.create Operator node client' ~default_operator:bootstrap2_key
  in
  let sc_rollup_client' = Sc_rollup_client.create sc_rollup_node' in
  let* _configuration_filename =
    Sc_rollup_node.config_init sc_rollup_node' sc_rollup
  in
  let* () = Sc_rollup_node.run sc_rollup_node' in

  let* rollup_node2_catchup_level =
    Sc_rollup_node.wait_for_level
      ~timeout:3.
      sc_rollup_node'
      level_after_cementation
  in
  Check.(rollup_node2_catchup_level = level_after_cementation)
    Check.int
    ~error_msg:"Current level has moved past cementation inbox level (%L = %R)" ;
  (* Check that no commitment was published. *)
  let* rollup_node2_last_published_commitment =
    Sc_rollup_client.last_published_commitment ~hooks sc_rollup_client'
  in
  let rollup_node2_last_published_commitment_inbox_level =
    Option.map inbox_level rollup_node2_last_published_commitment
  in
  let () =
    Check.(rollup_node2_last_published_commitment_inbox_level = None)
      (Check.option Check.int)
      ~error_msg:
        "Commitment has been published at a level different than expected (%L \
         = %R)"
  in
  (* Check that the commitment stored by the second rollup node
     is the same commmitment stored by the first rollup node. *)
  let* rollup_node2_stored_commitment =
    Sc_rollup_client.last_stored_commitment ~hooks sc_rollup_client'
  in
  let () =
    Check.(
      Option.map hash rollup_node1_stored_commitment
      = Option.map hash rollup_node2_stored_commitment)
      (Check.option Check.string)
      ~error_msg:
        "Commitment stored by first and second rollup nodes differ (%L = %R)"
  in

  (* Bake other commitment_period levels and check that rollup_node2 is
     able to publish a commitment. *)
  let* () = bake_levels commitment_period client' in
  let commitment_inbox_level = commitment_inbox_level + commitment_period in
  let* _ =
    Sc_rollup_node.wait_for_level
      ~timeout:3.
      sc_rollup_node'
      (level_after_cementation + commitment_period)
  in
  let* rollup_node2_last_published_commitment =
    Sc_rollup_client.last_published_commitment ~hooks sc_rollup_client'
  in
  let rollup_node2_last_published_commitment_inbox_level =
    Option.map inbox_level rollup_node2_last_published_commitment
  in
  let () =
    Check.(
      rollup_node2_last_published_commitment_inbox_level
      = Some commitment_inbox_level)
      (Check.option Check.int)
      ~error_msg:
        "Commitment has been published at a level different than expected (%L \
         = %R)"
  in
  let () =
    Check.(
      Option.map predecessor rollup_node2_last_published_commitment
      = Some cemented_commitment_hash)
      (Check.option Check.string)
      ~error_msg:
        "Predecessor fo commitment published by rollup_node2 should be the \
         cemented commitment (%L = %R)"
  in
  return ()

(* Test that the level when a commitment was first published is fetched correctly
   by rollup nodes. *)
let first_published_level_is_global _protocol sc_rollup_node sc_rollup node
    client =
  (* Rollup node 1 processes messages, produces and publishes two commitments. *)
  let* genesis_info =
    RPC.Client.call ~hooks client
    @@ RPC.get_chain_block_context_sc_rollup_genesis_info sc_rollup
  in
  let init_level = JSON.(genesis_info |-> "level" |> as_int) in
  let* commitment_period = get_sc_rollup_commitment_period_in_blocks client in
  let* () = Sc_rollup_node.run sc_rollup_node in
  let sc_rollup_client = Sc_rollup_client.create sc_rollup_node in
  let* level =
    Sc_rollup_node.wait_for_level ~timeout:3. sc_rollup_node init_level
  in
  Check.(level = init_level)
    Check.int
    ~error_msg:"Current level has moved past origination level (%L = %R)" ;
  let* () = bake_levels commitment_period client in
  let* commitment_inbox_level =
    Sc_rollup_node.wait_for_level
      ~timeout:3.
      sc_rollup_node
      (init_level + commitment_period)
  in
  (* Bake `block_finality_time` additional level to ensure that block number
     `init_level + sc_rollup_commitment_period_in_blocks` is processed by
     the rollup node as finalized. *)
  let* () = bake_levels block_finality_time client in
  let* commitment_finalized_level =
    Sc_rollup_node.wait_for_level
      ~timeout:3.
      sc_rollup_node
      (commitment_inbox_level + block_finality_time)
  in
  let* rollup_node1_published_commitment =
    Sc_rollup_client.last_published_commitment ~hooks sc_rollup_client
  in
  Check.(
    Option.map inbox_level rollup_node1_published_commitment
    = Some commitment_inbox_level)
    (Check.option Check.int)
    ~error_msg:
      "Commitment has been published at a level different than expected (%L = \
       %R)" ;
  (* Bake an additional block for the commitment to be included. *)
  let* () = Client.bake_for_and_wait client in
  let* commitment_publish_level =
    Sc_rollup_node.wait_for_level sc_rollup_node (commitment_finalized_level + 1)
  in
  let* rollup_node1_published_commitment =
    Sc_rollup_client.last_published_commitment ~hooks sc_rollup_client
  in
  Check.(
    Option.bind rollup_node1_published_commitment first_published_at_level
    = Some commitment_publish_level)
    (Check.option Check.int)
    ~error_msg:
      "Level at which commitment has first been published (%L) is wrong. \
       Expected %R." ;
  let* () = Sc_rollup_node.terminate sc_rollup_node in
  (* Rollup node 2 starts and processes enough levels to publish a commitment.*)
  let bootstrap2_key = Constant.bootstrap2.public_key_hash in
  let* client' = Client.init ?endpoint:(Some (Node node)) () in
  let sc_rollup_node' =
    Sc_rollup_node.create Operator node client' ~default_operator:bootstrap2_key
  in
  let sc_rollup_client' = Sc_rollup_client.create sc_rollup_node' in
  let* _configuration_filename =
    Sc_rollup_node.config_init sc_rollup_node' sc_rollup
  in
  let* () = Sc_rollup_node.run sc_rollup_node' in

  let* rollup_node2_catchup_level =
    Sc_rollup_node.wait_for_level
      ~timeout:3.
      sc_rollup_node'
      commitment_finalized_level
  in
  Check.(rollup_node2_catchup_level = commitment_finalized_level)
    Check.int
    ~error_msg:"Current level has moved past cementation inbox level (%L = %R)" ;
  (* Check that no commitment was published. *)
  let* rollup_node2_published_commitment =
    Sc_rollup_client.last_published_commitment ~hooks sc_rollup_client'
  in
  check_commitment_eq
    ( Option.map (fun (_, c, _) -> c) rollup_node1_published_commitment,
      "published by rollup node 1" )
    ( Option.map (fun (_, c, _) -> c) rollup_node2_published_commitment,
      "published by rollup node 2" ) ;
  let () =
    Check.(
      Option.bind rollup_node1_published_commitment first_published_at_level
      = Option.bind rollup_node2_published_commitment first_published_at_level)
      (Check.option Check.int)
      ~error_msg:
        "Rollup nodes do not agree on level when commitment was first \
         published (%L = %R)"
  in
  return ()

(* Check that the SC rollup is correctly originated with a boot sector.
   -------------------------------------------------------

   Originate a rollup with a custom boot sector and check if the RPC returns it.
*)
let test_rollup_arith_origination_boot_sector =
  let boot_sector = "10 10 10 + +" in

  let go client sc_rollup =
    let* client_boot_sector =
      RPC.Client.call ~hooks client
      @@ RPC.get_chain_block_context_sc_rollup_boot_sector sc_rollup
    in
    let client_boot_sector = JSON.as_string client_boot_sector in
    Check.(boot_sector = client_boot_sector)
      Check.string
      ~error_msg:"expected value %L, got %R" ;
    Lwt.return_unit
  in

  regression_test
    ~__FILE__
    ~tags:["sc_rollup"; "run"]
    (Format.asprintf "originate arith with boot sector")
    (fun protocol ->
      setup ~protocol @@ fun node client ->
      with_fresh_rollup
        ~kind:"arith"
        ~boot_sector
        (fun sc_rollup _sc_rollup_node _filename -> go client sc_rollup)
        node
        client)

(* Check that a node makes use of the boot sector.
   -------------------------------------------------------

   Originate 2 rollups with different boot sectors to check if the are
   actually different.
*)
let test_rollup_node_uses_arith_boot_sector =
  let go_boot client sc_rollup sc_rollup_node =
    let* genesis_info =
      RPC.Client.call ~hooks client
      @@ RPC.get_chain_block_context_sc_rollup_genesis_info sc_rollup
    in
    let init_level = JSON.(genesis_info |-> "level" |> as_int) in

    let* () = Sc_rollup_node.run sc_rollup_node in

    let sc_rollup_client = Sc_rollup_client.create sc_rollup_node in
    let* level =
      Sc_rollup_node.wait_for_level ~timeout:3. sc_rollup_node init_level
    in

    let* () = send_text_messages client sc_rollup ["10 +"] in
    let* _ =
      Sc_rollup_node.wait_for_level ~timeout:3. sc_rollup_node (level + 1)
    in

    Sc_rollup_client.state_hash ~hooks sc_rollup_client
  in

  let with_booted ~boot_sector node client =
    with_fresh_rollup
      ~kind:"arith"
      ~boot_sector
      (fun sc_rollup sc_rollup_node _filename ->
        go_boot client sc_rollup sc_rollup_node)
      node
      client
  in

  regression_test
    ~__FILE__
    ~tags:["sc_rollup"; "run"; "node"]
    (Format.asprintf "ensure arith boot sector is used")
    (fun protocol ->
      setup ~protocol @@ fun node client x ->
      let* state_hash1 =
        with_booted ~boot_sector:"10 10 10 + +" node client x
      in
      let* state_hash2 = with_booted ~boot_sector:"31" node client x in
      Check.(state_hash1 <> state_hash2)
        Check.string
        ~error_msg:"State hashes should be different! (%L, %R)" ;

      Lwt.return_unit)

(* Initializes a client with an existing account being
   [Constants.tz4_account]. *)
let client_with_initial_keys ~protocol ~kind =
  setup ~protocol @@ with_fresh_rollup ~kind
  @@ fun _sc_rollup sc_rollup_node _filename ->
  let sc_client = Sc_rollup_client.create sc_rollup_node in
  let account = Constant.tz4_account in
  let* () = Sc_rollup_client.import_secret_key account sc_client in
  return (sc_client, account)

(* Check that the client can show the address of a registered account.
   -------------------------------------------------------------------
*)
let test_rollup_client_show_address ~kind =
  test
    ~__FILE__
    ~tags:["run"; "client"]
    "Shows the address of a registered account"
    (fun protocol ->
      let* sc_client, account = client_with_initial_keys ~protocol ~kind in
      let* shown_account =
        Sc_rollup_client.show_address
          ~alias:account.Account.aggregate_alias
          sc_client
      in
      if
        account.aggregate_public_key_hash
        <> shown_account.aggregate_public_key_hash
      then
        failwith
          (Printf.sprintf
             "Expecting %s, got %s as public key hash from the client."
             account.aggregate_public_key_hash
             shown_account.aggregate_public_key_hash)
      else if account.aggregate_public_key <> shown_account.aggregate_public_key
      then
        failwith
          (Printf.sprintf
             "Expecting %s, got %s as public key from the client."
             account.aggregate_public_key
             shown_account.aggregate_public_key)
      else if account.aggregate_secret_key <> shown_account.aggregate_secret_key
      then
        let (Unencrypted sk) = shown_account.aggregate_secret_key in
        let (Unencrypted expected_sk) = shown_account.aggregate_secret_key in
        failwith
          (Printf.sprintf
             "Expecting %s, got %s as secret key from the client."
             expected_sk
             sk)
      else return ())

(* Check that the client can generate keys.
   ----------------------------------------
*)
let test_rollup_client_generate_keys ~kind =
  test
    ~__FILE__
    ~tags:["run"; "client"]
    "Generates new tz4 keys"
    (fun protocol ->
      setup ~protocol @@ with_fresh_rollup ~kind
      @@ fun _sc_rollup sc_rollup_node _filename ->
      let sc_client = Sc_rollup_client.create sc_rollup_node in
      let alias = "test_key" in
      let* () = Sc_rollup_client.generate_keys ~alias sc_client in
      let* _account = Sc_rollup_client.show_address ~alias sc_client in
      return ())

(* Check that the client can list keys.
   ------------------------------------
*)
let test_rollup_client_list_keys ~kind =
  test
    ~__FILE__
    ~tags:["run"; "client"]
    "Lists known aliases in the client"
    (fun protocol ->
      let* sc_client, account = client_with_initial_keys ~kind ~protocol in
      let* maybe_keys = Sc_rollup_client.list_keys sc_client in
      let expected_keys =
        [(account.aggregate_alias, account.aggregate_public_key_hash)]
      in
      if List.equal ( = ) expected_keys maybe_keys then return ()
      else
        let pp ppf l =
          Format.pp_print_list
            ~pp_sep:(fun ppf () -> Format.fprintf ppf "\n")
            (fun ppf (a, k) -> Format.fprintf ppf "%s: %s" a k)
            ppf
            l
        in
        Test.fail
          ~__LOC__
          "Expecting\n@[%a@]\ngot\n@[%a@]\nas keys from the client."
          pp
          expected_keys
          pp
          maybe_keys)

let publish_dummy_commitment ?(number_of_ticks = 1) ~inbox_level ~predecessor
    ~sc_rollup ~src client =
  let commitment : Sc_rollup_client.commitment =
    {
      compressed_state = Constant.sc_rollup_compressed_state;
      inbox_level;
      predecessor;
      number_of_ticks;
    }
  in
  let*! () = publish_commitment ~src ~commitment client sc_rollup in
  let* () = Client.bake_for_and_wait client in
  get_staked_on_commitment ~sc_rollup ~staker:src client

let test_consecutive_commitments ~kind =
  regression_test
    ~__FILE__
    ~tags:["sc_rollup"; "l1"; "commitment"; kind]
    (Format.asprintf "%s - consecutive commitments" kind)
    (fun protocol ->
      setup ~protocol @@ fun _node client bootstrap1_key ->
      let* inbox_level = Client.level client in
      let* sc_rollup = originate_sc_rollup ~kind ~src:bootstrap1_key client in
      let operator = Constant.bootstrap1.public_key_hash in
      let* {commitment_period_in_blocks; _} = get_sc_rollup_constants client in
      (* As we did no publish any commitment yet, this is supposed to fail. *)
      let*? process =
        RPC.Client.spawn client
        @@ RPC.get_chain_block_context_sc_rollup_staker_staked_on_commitment
             ~sc_rollup
             operator
      in
      let* () = Process.check_error ~msg:(rex "Unknown staker") process in
      let* predecessor, _ =
        last_cemented_commitment_hash_with_level ~sc_rollup client
      in
      let* commit_hash =
        publish_dummy_commitment
          ~inbox_level:(inbox_level + commitment_period_in_blocks + 1)
          ~predecessor
          ~sc_rollup
          ~src:operator
          client
      in
      let* _commit_hash =
        publish_dummy_commitment
          ~inbox_level:(inbox_level + (2 * commitment_period_in_blocks) + 1)
          ~predecessor:commit_hash
          ~sc_rollup
          ~src:operator
          client
      in
      unit)

(* Refutation game scenarios
   -------------------------
*)

(*

   To check the refutation game logic, we evaluate a scenario with one
   honest rollup node and one dishonest rollup node configured as with
   a given [loser_mode].

   For a given sequence of [inputs], distributed amongst several
   levels, with some possible [empty_levels]. We check that at some
   [final_level], the crime does not pay: the dishonest node has losen
   its deposit while the honest one has not.

*)
let test_refutation_scenario ?commitment_period ?challenge_window variant ~kind
    (loser_mode, inputs, final_level, empty_levels, stop_loser_at) =
  test_scenario
    ?commitment_period
    ~kind
    ~timeout:10
    ?challenge_window
    {
      tags = ["refutation"; "node"];
      variant;
      description = "refutation games winning strategies";
    }
  @@ fun _protocol sc_rollup_node sc_rollup_address node client ->
  let bootstrap1_key = Constant.bootstrap1.public_key_hash in
  let bootstrap2_key = Constant.bootstrap2.public_key_hash in

  let sc_rollup_node2 =
    Sc_rollup_node.create Operator node client ~default_operator:bootstrap2_key
  in
  let* _configuration_filename =
    Sc_rollup_node.config_init ~loser_mode sc_rollup_node2 sc_rollup_address
  in
  let* () = Sc_rollup_node.run sc_rollup_node
  and* () = Sc_rollup_node.run sc_rollup_node2 in

  let start_level = Node.get_level node in

  let stop_loser level =
    if List.mem level stop_loser_at then
      Sc_rollup_node.terminate sc_rollup_node2
    else return ()
  in

  let rec consume_inputs i = function
    | [] -> return ()
    | inputs :: next_batches as all ->
        let level = start_level + i in
        let* () = stop_loser level in
        if List.mem level empty_levels then
          let* () = Client.bake_for_and_wait client in
          consume_inputs (i + 1) all
        else
          let* () =
            Lwt_list.iter_s (send_text_messages client sc_rollup_address) inputs
          in
          let* () = Client.bake_for_and_wait client in
          consume_inputs (i + 1) next_batches
  in
  let* () = consume_inputs 0 inputs in
  let* after_inputs_level = Client.level client in

  let hook i =
    let level = after_inputs_level + i in
    stop_loser level
  in
  let* () = bake_levels ~hook (final_level - List.length inputs) client in

  let*! honest_deposit =
    RPC.Contracts.get_frozen_bonds ~contract_id:bootstrap1_key client
  in
  let*! loser_deposit =
    RPC.Contracts.get_frozen_bonds ~contract_id:bootstrap2_key client
  in
  let* {stake_amount; _} = get_sc_rollup_constants client in

  Check.(
    (JSON.as_int honest_deposit = Tez.to_mutez stake_amount)
      int
      ~error_msg:"expecting deposit for honest participant = %R, got %L") ;
  Check.(
    (JSON.as_int loser_deposit = 0)
      int
      ~error_msg:"expecting loss for dishonest participant = %R, got %L") ;
  return ()

let rec swap i l =
  if i <= 0 then l
  else match l with [_] | [] -> l | x :: y :: l -> y :: swap (i - 1) (x :: l)

let inputs_for n =
  List.init n @@ fun i ->
  [swap i ["3 3 +"; "1"; "1 1 x"; "3 7 8 + * y"; "2 2 out"]]

let test_refutation protocols ~kind =
  let challenge_window = 10 in
  [
    ("inbox_proof_at_genesis", ("3 0 0", inputs_for 10, 80, [], []));
    ("pvm_proof_at_genesis", ("3 0 1", inputs_for 10, 80, [], []));
    ("inbox_proof", ("5 0 0", inputs_for 10, 80, [], []));
    ("inbox_proof_one_empty_level", ("6 0 0", inputs_for 10, 80, [2], []));
    ( "inbox_proof_many_empty_levels",
      ("9 0 0", inputs_for 10, 80, [2; 3; 4], []) );
    ("pvm_proof_0", ("5 0 1", inputs_for 10, 80, [], []));
    ("pvm_proof_1", ("7 1 2", inputs_for 10, 80, [], []));
    ("pvm_proof_2", ("7 2 5", inputs_for 7, 80, [], []));
    ("pvm_proof_3", ("9 2 5", inputs_for 7, 80, [4; 5], []));
    ("timeout", ("5 0 1", inputs_for 10, 80, [], [35]));
  ]
  |> List.iter (fun (variant, inputs) ->
         test_refutation_scenario
           ~kind
           ~challenge_window
           variant
           inputs
           protocols)

(** Helper to check that the operation whose hash is given is successfully
    included (applied) in the current head block. *)
let check_op_included =
  let get_op_status op =
    JSON.(op |-> "metadata" |-> "operation_result" |-> "status" |> as_string)
  in
  fun ~oph client ->
    let* head = RPC.Client.call client @@ RPC.get_chain_block () in
    (* Operations in a block are encoded as a list of lists of operations
       [ consensus; votes; anonymous; manager ]. Manager operations are
       at index 3 in the list. *)
    let ops = JSON.(head |-> "operations" |=> 3 |> as_list) in
    let op_contents =
      match
        List.find_opt (fun op -> oph = JSON.(op |-> "hash" |> as_string)) ops
      with
      | None -> []
      | Some op -> JSON.(op |-> "contents" |> as_list)
    in
    match op_contents with
    | [op] ->
        let status = get_op_status op in
        if String.equal status "applied" then unit
        else
          Test.fail
            ~__LOC__
            "Unexpected operation %s status: got %S instead of 'applied'."
            oph
            status
    | _ ->
        Test.fail
          "Expected to have one operation with hash %s, but got %d"
          oph
          (List.length op_contents)

(** Helper function that allows to inject the given operation in a node, bake a
    block, and check that the operation is successfully applied in the baked
    block. *)
let bake_operation_via_rpc client op =
  let* (`OpHash oph) = Operation.Manager.inject [op] client in
  let* () = Client.bake_for_and_wait client in
  check_op_included ~oph client

(** This helper function constructs the following commitment tree by baking and
    publishing commitments (but without cementing them):
    ---- c1 ---- c2 ---- c31 ---- c311
                  \
                   \---- c32 ---- c321

   Commits c1, c2, c31 and c311 are published by [operator1]. The forking
   branch c32 -- c321 is published by [operator2].
*)
let mk_forking_commitments node client ~sc_rollup ~operator1 ~operator2 =
  let* {commitment_period_in_blocks; _} = get_sc_rollup_constants client in
  (* This is the starting level on top of wich we'll construct the tree. *)
  let starting_level = Node.get_level node in
  let mk_commit ~src ~ticks ~depth ~pred =
    (* Compute the inbox level for which we'd like to commit *)
    let inbox_level = starting_level + (commitment_period_in_blocks * depth) in
    (* d is the delta between the target inbox level and the current level *)
    let d = inbox_level - Node.get_level node in
    (* Bake sufficiently many blocks to be able to commit for the desired inbox
       level. We may actually bake no blocks if d <= 0 *)
    let* () = repeat d (fun () -> Client.bake_for_and_wait client) in
    publish_dummy_commitment
      ~inbox_level
      ~predecessor:pred
      ~sc_rollup
      ~number_of_ticks:ticks
      ~src
      client
  in
  (* Retrieve the latest commitment *)
  let* c0, _ = last_cemented_commitment_hash_with_level ~sc_rollup client in
  (* Construct the tree of commitments. Fork c32 and c321 is published by
     operator2. We vary ticks to have different hashes when commiting on top of
     the same predecessor. *)
  let* c1 = mk_commit ~ticks:1 ~depth:1 ~pred:c0 ~src:operator1 in
  let* c2 = mk_commit ~ticks:2 ~depth:2 ~pred:c1 ~src:operator1 in
  let* c31 = mk_commit ~ticks:31 ~depth:3 ~pred:c2 ~src:operator1 in
  let* c32 = mk_commit ~ticks:32 ~depth:3 ~pred:c2 ~src:operator2 in
  let* c311 = mk_commit ~ticks:311 ~depth:4 ~pred:c31 ~src:operator1 in
  let* c321 = mk_commit ~ticks:321 ~depth:4 ~pred:c32 ~src:operator2 in
  return (c1, c2, c31, c32, c311, c321)

(** This helper initializes a rollup and builds a commitment tree of the form:
    ---- c1 ---- c2 ---- c31 ---- c311
                  \
                   \---- c32 ---- c321
    Then, it calls the given scenario on it.
*)
let test_forking_scenario ~title ~scenario protocols =
  regression_test
    ~__FILE__
    ~tags:["l1"; "commitment"; "cement"; "fork"; "dispute"]
    title
    (fun protocol ->
      (* Choosing challenge_windows to be quite longer than commitment_period
         to avoid being in a situation where the first commitment in the result
         of [mk_forking_commitments] is cementable without further bakes. *)
      let commitment_period = 3 in
      let challenge_window = commitment_period * 7 in
      setup ~commitment_period ~challenge_window ~protocol
      @@ fun node client _bootstrap1_key ->
      (* Originate a Sc rollup. *)
      let* sc_rollup = originate_sc_rollup client ~parameters_ty:"unit" in
      (* Building a forking commitments tree. *)
      let operator1 = Constant.bootstrap1 in
      let operator2 = Constant.bootstrap2 in
      let level0 = Node.get_level node in
      let* commits =
        mk_forking_commitments
          node
          client
          ~sc_rollup
          ~operator1:operator1.public_key_hash
          ~operator2:operator2.public_key_hash
      in
      let level1 = Node.get_level node in
      scenario
        client
        node
        ~sc_rollup
        ~operator1
        ~operator2
        commits
        level0
        level1)
    protocols

(** Given a commitment tree constructed by {test_forking_scenario}, this function:
    - tests different (failing and non-failing) cementation of commitments
      and checks the returned error for each situation (in case of failure);
    - resolves the dispute on top of c2, and checks that the defeated branch
      is removed, while the alive one can be cemented.
*)
let test_no_cementation_if_parent_not_lcc_or_if_disputed_commit protocols =
  test_forking_scenario
    ~title:
      "commitments: publish, and try to cement not on top of LCC or disputed"
    ~scenario:
      (fun client _node ~sc_rollup ~operator1 ~operator2 commits level0 level1 ->
      let c1, c2, c31, c32, c311, c321 = commits in
      let* constants = get_sc_rollup_constants client in
      let challenge_window = constants.challenge_window_in_blocks in

      (* More convenient Wrapper around cement_commitment for the tests below *)
      let cement ?fail l =
        Lwt_list.iter_s
          (fun hash -> cement_commitment client ~sc_rollup ~hash ?fail)
          l
      in
      let missing_blocks_to_cement = level0 + challenge_window - level1 in
      let* () =
        if missing_blocks_to_cement <= 0 then unit (* We can already cement *)
        else
          let* () =
            repeat (missing_blocks_to_cement - 1) (fun () ->
                Client.bake_for_and_wait client)
          in
          (* We cannot cement yet! *)
          let* () = cement [c1] ~fail:commit_too_recent in
          (* After these blocks, we should be able to cement all commitments
             (modulo cementation ordering & disputes resolution) *)
          repeat challenge_window (fun () -> Client.bake_for_and_wait client)
      in
      (* We cannot cement any of the commitments before cementing c1 *)
      let* () = cement [c2; c31; c32; c311; c321] ~fail:parent_not_lcc in
      (* But, we can cement c1 and then c2, in this order *)
      let* () = cement [c1; c2] in
      (* We cannot cement c31 or c32 on top of c2 because they are disputed *)
      let* () = cement [c31; c32] ~fail:disputed_commit in
      (* Of course, we cannot cement c311 or c321 because their parents are not
         cemented. *)
      let* () = cement ~fail:parent_not_lcc [c311; c321] in

      (* +++ dispute resolution +++
         Let's resolve the dispute between operator1 and operator2 on the fork
         c31 vs c32. [operator1] will make a bad initial dissection, so it
         loses the dispute, and the branch c32 --- c321 dies. *)

      (* [operator1] starts a dispute. *)
      let module M = Operation.Manager in
      let* () =
        bake_operation_via_rpc client
        @@ M.make ~source:operator2
        @@ M.sc_rollup_refute ~sc_rollup ~opponent:operator1.public_key_hash ()
      in
      (* [operator1] makes a dissection. it will lose here because the dissection
         is ill-formed. *)
      let refutation = M.{choice_tick = 0; refutation_step = Dissection []} in
      let* () =
        bake_operation_via_rpc client
        @@ M.make ~source:operator2
        @@ M.sc_rollup_refute
             ~sc_rollup
             ~opponent:operator1.public_key_hash
             ~refutation
             ()
      in
      (* Attempting to cement defeated branch will fail. *)
      let* () = cement ~fail:commit_doesnt_exit [c32; c321] in
      (* Now, we can cement c31 on top of c2 and c311 on top of c31. *)
      cement [c31; c311])
    protocols

(** Given a commitment tree constructed by {test_forking_scenario}, this test
    starts a dispute and makes a first valid dissection move.
*)
let test_valid_dispute_dissection protocols =
  test_forking_scenario
    ~title:"valid dispute dissection"
    ~scenario:
      (fun client _node ~sc_rollup ~operator1 ~operator2 commits _level0 _level1 ->
      let c1, c2, c31, c32, _c311, _c321 = commits in
      (* More convenient wrapper around cement_commitment for the tests below *)
      let cement ?fail l =
        Lwt_list.iter_s
          (fun hash -> cement_commitment client ~sc_rollup ~hash ?fail)
          l
      in
      let* constants = get_sc_rollup_constants client in
      let challenge_window = constants.challenge_window_in_blocks in
      let commitment_period = constants.commitment_period_in_blocks in
      let number_of_sections_in_dissection =
        constants.number_of_sections_in_dissection
      in
      let* () =
        (* Be able to cement both c1 and c2 *)
        repeat (challenge_window + commitment_period) (fun () ->
            Client.bake_for_and_wait client)
      in
      let* () = cement [c1; c2] in
      let module M = Operation.Manager in
      (* The source initialises a dispute. *)
      let source = operator2 in
      let opponent = operator1.public_key_hash in
      let* () =
        bake_operation_via_rpc client
        @@ M.make ~source
        @@ M.sc_rollup_refute ~sc_rollup ~opponent ()
      in
      (* Construct a valid dissection with valid initial hash of size
         [sc_rollup.number_of_sections_in_dissection]. The state hash below is
         the hash of the state computed after submitting the first commitment c1
         (which is also equal to states's hashes of subsequent commitments, as we
         didn't add any message in inboxes). If this hash needs to be recomputed,
         run this test with --verbose and grep for 'compressed_state' in the
         produced logs. *)
      let state_hash =
        "scs11VNjWyZw4Tgbvsom8epQbox86S2CKkE1UAZkXMM7Pj8MQMLzMf"
      in

      let rec aux i acc =
        if i = number_of_sections_in_dissection - 1 then
          List.rev ({M.state_hash = None; tick = i} :: acc)
        else aux (i + 1) ({M.state_hash = Some state_hash; tick = i} :: acc)
      in
      (* Inject a valid dissection move *)
      let refutation =
        M.{choice_tick = 0; refutation_step = Dissection (aux 0 [])}
      in

      let* () =
        bake_operation_via_rpc client
        @@ M.make ~source
        @@ M.sc_rollup_refute ~sc_rollup ~opponent ~refutation ()
      in
      (* We cannot cement neither c31, nor c32 because refutation game hasn't
         ended. *)
      cement [c31; c32] ~fail:"Attempted to cement a disputed commitment")
    protocols

let register ~kind ~protocols =
  test_origination ~kind protocols ;
  test_rollup_node_running ~kind protocols ;
  test_rollup_get_genesis_info ~kind protocols ;
  test_rollup_get_chain_block_context_sc_rollup_last_cemented_commitment_hash_with_level
    ~kind
    protocols ;
  test_rollup_inbox_size ~kind protocols ;
  test_rollup_inbox_current_messages_hash ~kind protocols ;
  test_rollup_inbox_of_rollup_node ~kind "basic" basic_scenario protocols ;
  test_rollup_inbox_of_rollup_node
    ~kind
    "stops"
    sc_rollup_node_stops_scenario
    protocols ;
  test_rollup_inbox_of_rollup_node
    ~kind
    "disconnects"
    sc_rollup_node_disconnects_scenario
    protocols ;
  test_rollup_inbox_of_rollup_node
    ~kind
    "handles_chain_reorg"
    sc_rollup_node_handles_chain_reorg
    protocols ;
  test_rollup_node_boots_into_initial_state protocols ~kind ;
  test_rollup_node_advances_pvm_state protocols ~kind ;
  test_commitment_scenario
    "commitment_is_stored"
    commitment_stored
    protocols
    ~kind ;
  test_commitment_scenario
    "robust_to_failures"
    commitment_stored_robust_to_failures
    protocols
    ~kind ;
  test_commitment_scenario
    ~extra_tags:["modes"; "observer"]
    "observer_does_not_publish"
    (mode_publish Observer false)
    protocols
    ~kind ;
  test_commitment_scenario
    ~extra_tags:["modes"; "maintenance"]
    "maintenance_publishes"
    (mode_publish Maintenance true)
    protocols
    ~kind ;
  test_commitment_scenario
    ~extra_tags:["modes"; "batcher"]
    "batcher_does_not_publish"
    (mode_publish Batcher false)
    protocols
    ~kind ;
  test_commitment_scenario
    ~extra_tags:["modes"; "operator"]
    "operator_publishes"
    (mode_publish Operator true)
    protocols
    ~kind ;
  test_commitment_scenario
    ~commitment_period:15
    ~challenge_window:10080
    "node_use_proto_param"
    commitment_stored
    protocols
    ~kind ;
  test_commitment_scenario
    "non_final_level"
    commitment_not_stored_if_non_final
    protocols
    ~kind ;
  test_commitment_scenario
    "messages_reset"
    commitments_messages_reset
    protocols
    ~kind ;
  test_commitment_scenario
    "handles_chain_reorgs"
    commitments_reorgs
    protocols
    ~kind ;
  test_commitment_scenario
    ~challenge_window:1
    "no_commitment_publish_before_lcc"
    (* TODO: https://gitlab.com/tezos/tezos/-/issues/2976
       change tests so that we do not need to repeat custom parameters. *)
    commitment_before_lcc_not_published
    protocols
    ~kind ;
  test_commitment_scenario
    "first_published_at_level_global"
    first_published_level_is_global
    protocols
    ~kind ;
  test_consecutive_commitments protocols ~kind ;
  test_refutation protocols ~kind

let register ~protocols =
  (* PVM-independent tests. We still need to specify a PVM kind
     because the tezt will need to originate a rollup. However,
     the tezt will not test for PVM kind specific featued. *)
  test_rollup_client_gets_address protocols ~kind:"wasm_2_0_0" ;
  test_rollup_node_configuration protocols ~kind:"wasm_2_0_0" ;
  test_rollup_list protocols ~kind:"wasm_2_0_0" ;
  test_rollup_client_show_address protocols ~kind:"wasm_2_0_0" ;
  test_rollup_client_generate_keys protocols ~kind:"wasm_2_0_0" ;
  test_rollup_client_list_keys protocols ~kind:"wasm_2_0_0" ;
  (* Specific Arith PVM tezts *)
  test_rollup_arith_origination_boot_sector protocols ;
  test_rollup_node_uses_arith_boot_sector protocols ;
  (* Shared tezts - will be executed for both PVMs. *)
  register ~kind:"wasm_2_0_0" ~protocols ;
  register ~kind:"arith" ~protocols ;
  test_no_cementation_if_parent_not_lcc_or_if_disputed_commit protocols ;
  test_valid_dispute_dissection protocols
