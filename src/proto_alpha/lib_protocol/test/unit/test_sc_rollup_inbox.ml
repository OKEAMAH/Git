(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2022 Nomadic Labs, <contact@nomadic-labs.com>               *)
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
Component:  Protocol (smart contract rollup inbox)
Invocation: dune exec src/proto_alpha/lib_protocol/test/unit/main.exe \
-- test "^\[Unit\] sc rollup inbox$"
Subject:    These unit tests check the off-line inbox implementation for
smart contract rollups
*)
open Protocol

let lift k = Environment.wrap_tzresult k

let lift_lwt k = Lwt.map Environment.wrap_tzresult k

module Inbox_repr = Sc_rollup_inbox_repr

let rollup_address = Sc_rollup_repr.Address.zero

let first_level = Raw_level_repr.(succ root)

module Proto_inbox = struct end

let serialize_external_msg msg =
  Sc_rollup_inbox_message_repr.(External msg |> serialize)

let assert_equal_message_proof ~__LOC__ found expected =
  let open Lwt_result_syntax in
  let*? expected = lift @@ serialize_external_msg expected in
  let found = Sc_rollup_inbox_message_repr.unsafe_to_string found in
  Assert.equal_string
    ~loc:__LOC__
    (Sc_rollup_inbox_message_repr.unsafe_to_string expected)
    found

module Node_inbox = struct
  module History_level_history =
    Bounded_history_repr.Make
      (struct
        let name = "history_level_history"
      end)
      (Inbox_repr.Merkelized_messages.Hash)
      (struct
        type nonrec t = Inbox_repr.Merkelized_messages.History.t

        let pp = Inbox_repr.Merkelized_messages.History.pp

        let equal = Inbox_repr.Merkelized_messages.History.equal

        let encoding = Inbox_repr.Merkelized_messages.History.encoding
      end)

  type node_inbox = {
    history : Inbox_repr.History.t;
    history_level_history : History_level_history.t;
    inbox : Inbox_repr.t;
  }

  let pp {history; history_level_history; inbox} =
    Format.printf
      "@,\
       @[@[<v 2>inbox:@,\
       %a@]@,\
       @[<v 2>history:@,\
       %a@]@,\
       @[<v 2>history_level_history:@,\
       %a@]@]"
      Inbox_repr.pp
      inbox
      Inbox_repr.History.pp
      history
      History_level_history.pp
      history_level_history

  let empty rollup_address origination_level =
    {
      history = Inbox_repr.History.empty ~capacity:1000L;
      history_level_history = History_level_history.empty ~capacity:1000L;
      inbox = Inbox_repr.empty rollup_address origination_level;
    }

  let fill_inbox node_inbox payloads =
    let open Result_syntax in
    let rec aux level node_inbox = function
      | [] -> return node_inbox
      | payloads :: rst ->
          let* payloads = lift @@ List.map_e serialize_external_msg payloads in
          let level_history =
            Inbox_repr.Merkelized_messages.History.empty ~capacity:100L
          in
          let* level_history, level_messages, history, inbox =
            lift
            @@ Inbox_repr.add_messages
                 node_inbox.history
                 node_inbox.inbox
                 level
                 payloads
                 level_history
                 None
          in
          let current_messages_hash = Inbox_repr.current_level_hash inbox in
          let () =
            assert (
              Inbox_repr.Merkelized_messages.(
                Hash.equal (hash level_messages) current_messages_hash))
          in
          let history_level_history =
            WithExceptions.Result.get_ok ~loc:__LOC__
            @@ History_level_history.remember
                 current_messages_hash
                 level_history
                 node_inbox.history_level_history
          in
          let level = Raw_level_repr.succ level in
          aux level {history; history_level_history; inbox} rst
    in
    aux first_level node_inbox payloads

  (** {!Sc_rollup_inbox_repr.form_history_proof} saves the old messages
      proof. We need an history that also contains the current history proof.
      This function applies the same logic of
      {!Sc_rollup_inbox_repr.form_history_proof} with the current history
      proof. *)
  let remember_current_history_proof node_inbox =
    let open Result_syntax in
    let* history, current_history_proof =
      lift @@ Inbox_repr.form_history_proof node_inbox.history node_inbox.inbox
    in
    let+ history =
      lift
      @@ Inbox_repr.History.remember
           (Inbox_repr.Internal_for_tests.hash_of_history_proof
              current_history_proof)
           current_history_proof
           history
    in
    {node_inbox with history}

  let construct_inbox ?(rollup_address = rollup_address)
      ?(origination_level = first_level) level_and_payloads =
    let open Result_syntax in
    let node_inbox = empty rollup_address origination_level in
    let* node_inbox = fill_inbox node_inbox level_and_payloads in
    let* node_inbox = remember_current_history_proof node_inbox in
    return node_inbox

  let get_level_messages node_inbox level_messages_hash =
    History_level_history.find
      level_messages_hash
      node_inbox.history_level_history
    |> Lwt.return

  let current_history_proof node_inbox =
    let open Result_syntax in
    let* _history, current_history_proof =
      lift @@ Inbox_repr.form_history_proof node_inbox.history node_inbox.inbox
    in
    return current_history_proof
end

let test_empty () =
  let inbox = Inbox_repr.empty rollup_address first_level in
  Assert.equal_int64
    ~loc:__LOC__
    (Inbox_repr.number_of_messages_during_commitment_period inbox)
    0L

let _unit_tests = [Tztest.tztest "Empty inbox" `Quick test_empty]

(* PBT test *)

let gen_input_message_size = QCheck2.Gen.(1 -- 10)

let gen_input_message = QCheck2.Gen.string_size gen_input_message_size

let gen_input_messages = QCheck2.Gen.(list_size (1 -- 40) gen_input_message)

let gen_input_messages_list ?(max_level = 50) () =
  QCheck2.Gen.(list_size (5 -- max_level) gen_input_messages)

let gen_message_index level_inputs =
  let open QCheck2.Gen in
  let max_message_index = List.length level_inputs - 1 in
  let* index = 0 -- max_message_index in
  return index

let gen_level_and_index inputs =
  let open QCheck2.Gen in
  let max_level = List.length inputs - 2 in
  let* level = 1 -- max_level in
  let level_inputs =
    WithExceptions.Option.get ~loc:__LOC__ @@ List.nth inputs level
  in
  let* index = gen_message_index level_inputs in
  return (level, index)

let gen_level_inputs_and_index =
  let open QCheck2.Gen in
  let* level_inputs = gen_input_messages in
  let* message_index = gen_message_index level_inputs in
  return (level_inputs, message_index)

let test_add_messages payloads =
  let open Lwt_result_syntax in
  let () =
    Format.(
      printf
        "[%a]"
        (pp_print_list
           (pp_print_list
              ~pp_sep:(fun fmt () -> pp_print_char fmt ';')
              pp_print_string))
        payloads)
  in
  let nb_payloads =
    List.fold_left
      (fun nb_payloads level_payloads ->
        nb_payloads + List.length level_payloads)
      0
      payloads
  in
  let*? node_inbox = Node_inbox.construct_inbox payloads in
  Assert.equal_int64
    ~loc:__LOC__
    (Int64.of_int nb_payloads)
    (Inbox_repr.number_of_messages_during_commitment_period node_inbox.inbox)

let test_get_message_payload payloads =
  let open Lwt_result_syntax in
  let*? node_inbox = Node_inbox.construct_inbox payloads in
  let*? current_history_proof = Node_inbox.current_history_proof node_inbox in
  List.iteri_es
    (fun level level_payloads ->
      (* no inbox at root level *)
      let level = succ level in
      let*! level_history, level_messages =
        Lwt.map (WithExceptions.Option.get ~loc:__LOC__)
        @@ Inbox_repr.find_level_messages
             node_inbox.history
             (Node_inbox.get_level_messages node_inbox)
             (Raw_level_repr.of_int32_exn (Int32.of_int level))
             current_history_proof
      in
      (List.iteri_es (fun message_index expected_input ->
           let found_payload =
             WithExceptions.Option.get ~loc:__LOC__
             @@ Inbox_repr.Merkelized_messages.find_message
                  level_history
                  ~message_index
                  level_messages
           in
           assert_equal_message_proof
             ~__LOC__
             (Inbox_repr.Merkelized_messages.get_message_payload found_payload)
             expected_input))
        level_payloads)
    payloads

let test_message_inclusion_proof (level_inputs, message_index) =
  let open Lwt_result_syntax in
  let*? node_inbox = Node_inbox.construct_inbox [level_inputs] in
  let () = Node_inbox.pp node_inbox in
  let*? current_history_proof = Node_inbox.current_history_proof node_inbox in
  let*! level_history, level_messages =
    Lwt.map (WithExceptions.Option.get ~loc:__LOC__)
    @@ Inbox_repr.find_level_messages
         node_inbox.history
         (Node_inbox.get_level_messages node_inbox)
         first_level
         current_history_proof
  in
  let () =
    Format.printf
      "@[<v>@[<v 2>History: %a@]@,@[<v 2>current message: %a@]@]"
      Inbox_repr.Merkelized_messages.History.pp
      level_history
      Inbox_repr.Merkelized_messages.pp
      level_messages
  in
  let proof =
    WithExceptions.Option.get ~loc:__LOC__
    @@ Inbox_repr.Merkelized_messages.produce_proof
         level_history
         ~message_index
         level_messages
  in
  let*? proved_payload, level, proved_index =
    lift @@ Inbox_repr.Merkelized_messages.verify_proof proof level_messages
  in
  let expected_input =
    WithExceptions.Option.get ~loc:__LOC__
    @@ List.nth level_inputs message_index
  in
  let* () = Assert.equal_int ~loc:__LOC__ proved_index message_index in
  let* () = assert_equal_message_proof ~__LOC__ proved_payload expected_input in
  let* () =
    Assert.equal_int32
      ~loc:__LOC__
      (Raw_level_repr.to_int32 level)
      (Raw_level_repr.to_int32 first_level)
  in
  return_unit

let unit_tests =
  [
    Tztest.tztest "test add payloads." `Quick (fun () ->
        test_add_messages [["\"11\""; "\"12\""]]);
    Tztest.tztest "Get message payload." `Quick (fun () ->
        test_get_message_payload [["\"11\""; "\"12\""]]);
    Tztest.tztest "Produce message proof." `Quick (fun () ->
        test_message_inclusion_proof (["\"11\""; "\"12\""], 0));
  ]

let pbt_tests =
  [
    Tztest.tztest_qcheck2
      ~name:"Added messages are available."
      (gen_input_messages_list
         ~max_level:
           (Int.pred
              Tezos_protocol_alpha_parameters.Default_parameters
              .constants_mainnet
                .sc_rollup
                .commitment_period_in_blocks)
         ())
      test_add_messages;
    Tztest.tztest_qcheck2
      ~name:"Get message payload."
      (gen_input_messages_list ())
      test_get_message_payload;
    Tztest.tztest_qcheck2
      ~name:"Produce message proof."
      gen_level_inputs_and_index
      test_message_inclusion_proof;
  ]

let tests = unit_tests @ pbt_tests
