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
          let level_messages = Inbox_repr.Merkelized_messages.empty level in
          let level_history =
            Inbox_repr.Merkelized_messages.History.empty ~capacity:100L
          in
          let res =
            Environment.wrap_tzresult
            @@ Inbox_repr.add_messages
                 node_inbox.history
                 node_inbox.inbox
                 level
                 payloads
                 level_history
                 level_messages
          in
          let level_history, level_messages, history, inbox =
            WithExceptions.Result.get_ok ~loc:__LOC__ res
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

  let construct_inbox ?(rollup_address = rollup_address)
      ?(origination_level = first_level) level_and_payloads =
    let node_inbox = empty rollup_address origination_level in
    fill_inbox node_inbox level_and_payloads
end

let test_empty () =
  let inbox = Inbox_repr.empty rollup_address first_level in
  Assert.equal_int64
    ~loc:__LOC__
    (Inbox_repr.number_of_messages_during_commitment_period inbox)
    0L

let test_get_message_payload payloads =
  let open Lwt_result_syntax in
  let*? node_inbox = Node_inbox.construct_inbox [payloads] in
  let () = Node_inbox.pp node_inbox in
  let level_messages_hash = Inbox_repr.current_level_hash node_inbox.inbox in
  let level_history =
    WithExceptions.Option.get ~loc:__LOC__
    @@ Node_inbox.History_level_history.find
         level_messages_hash
         node_inbox.history_level_history
  in
  let level_messages =
    WithExceptions.Option.get ~loc:__LOC__
    @@ Inbox_repr.Merkelized_messages.History.find
         level_messages_hash
         level_history
  in
  List.iteri_es
    (fun message_index message ->
      let*? expected_payload = lift @@ serialize_external_msg message in
      let message =
        WithExceptions.Option.get ~loc:__LOC__
        @@ Inbox_repr.Merkelized_messages.find_message
             level_history
             ~message_index:(message_index + 1)
             level_messages
      in
      let payload =
        Sc_rollup_inbox_message_repr.unsafe_to_string
          (Inbox_repr.Merkelized_messages.get_message_payload message)
      in
      Assert.equal_string
        ~loc:__LOC__
        (Sc_rollup_inbox_message_repr.unsafe_to_string expected_payload)
        payload)
    payloads

let unit_tests =
  [
    Tztest.tztest "Empty inbox" `Quick test_empty;
    Tztest.tztest "Get message payload." `Quick (fun () ->
        test_get_message_payload ["\"11\""; "\"12\""]);
  ]

(* PBT test *)

let gen_input_message_size = QCheck2.Gen.(10 -- 100)

let gen_input_message = QCheck2.Gen.string_size gen_input_message_size

let gen_input_messages = QCheck2.Gen.(list_size (1 -- 50) gen_input_message)

let test_add_messages payloads =
  let open Lwt_result_syntax in
  let nb_payloads = List.length payloads in
  let*? node_inbox = Node_inbox.construct_inbox [payloads] in
  Assert.equal_int64
    ~loc:__LOC__
    (Inbox_repr.number_of_messages_during_commitment_period node_inbox.inbox)
    (Int64.of_int nb_payloads)

let pbt_tests =
  [
    Tztest.tztest_qcheck2
      ~name:"Added messages are available."
      gen_input_messages
      test_add_messages;
    Tztest.tztest_qcheck2
      ~count:1
      ~name:"Get message payload."
      gen_input_messages
      test_get_message_payload;
  ]

let tests = unit_tests @ pbt_tests
