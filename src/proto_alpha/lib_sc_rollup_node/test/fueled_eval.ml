(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) Nomadic Labs, <contact@nomadic-labs.com>.                   *)
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
    Component:  Smart rollup node library
    Invocation: dune exec src/proto_alpha/lib_sc_rollup_node/test/main.exe \
                -- -f fueled_eval
    Subject:    Test PVM evaluation with fuel
*)

open Protocol.Alpha_context

let inputs_for n =
  let rec swap i l =
    if i <= 0 then l
    else match l with [_] | [] -> l | x :: y :: l -> y :: swap (i - 1) (x :: l)
  in
  List.concat @@ Stdlib.List.init n
  @@ fun i -> [swap i ["3 3 +"; "1"; "1 1 x"; "3 7 8 + * y"; "2 2 out"]]

let rec list_diff l1 l2 =
  match (l1, l2) with
  | _, [] -> l1
  | [], _ :: _ -> []
  | x :: l1, y :: l2 when x = y -> list_diff l1 l2
  | _ -> invalid_arg "no common prefix"

let build_chain node_ctxt ~length =
  let open Lwt_result_syntax in
  let* genesis = Helpers.add_l2_genesis_block node_ctxt ~boot_sector:"" in
  let messages =
    inputs_for length
    |> List.map @@ List.map @@ fun msg -> Sc_rollup.Inbox_message.External msg
  in
  let* blocks = Helpers.append_l2_blocks node_ctxt messages in
  return (genesis, blocks)

let eval_block_fuel_test kind node_ctxt =
  let module PVM = (val Components.pvm_of_kind kind) in
  let module Fueled = Fueled_pvm.Make (PVM) in
  let open Lwt_result_syntax in
  let* genesis, blocks = build_chain node_ctxt ~length:30 in
  let*! genesis_ctxt =
    Context.checkout node_ctxt.context genesis.header.context
  in
  let genesis_ctxt = WithExceptions.Option.get ~loc:__LOC__ genesis_ctxt in
  let*! genesis_state = PVM.State.find genesis_ctxt in
  let genesis_state = WithExceptions.Option.get ~loc:__LOC__ genesis_state in
  let* (_ : PVM.state) =
    List.fold_left_es
      (fun pred_state (block : Sc_rollup_block.t) ->
        let* block =
          Node_context.get_full_l2_block node_ctxt block.header.block_hash
        in
        let*! ctxt = Context.checkout node_ctxt.context block.header.context in
        let ctxt = WithExceptions.Option.get ~loc:__LOC__ ctxt in
        let*! state = PVM.State.find ctxt in
        let state = WithExceptions.Option.get ~loc:__LOC__ state in
        let fuel = Fuel.Accounted.of_ticks block.num_ticks in
        let* res =
          Fueled.Accounted.eval_block_inbox
            ~fuel
            node_ctxt
            (block.content.inbox, block.content.messages)
            pred_state
        in
        let* res_state, num_msgs, level, remaining_fuel =
          Tezos_layer2_store.Delayed_write_monad.apply node_ctxt res
        in
        let*! res_state_hash = PVM.state_hash res_state in
        let*! expected_state_hash = PVM.state_hash state in
        let level_str =
          Raw_level.to_int32 block.header.level |> Int32.to_string
        in
        Assert.Bool.equal
          ~loc:__LOC__
          ~msg:("remaining fuel is empty in " ^ level_str)
          (Fuel.Accounted.is_empty remaining_fuel)
          true ;
        Assert.Int.equal
          ~loc:__LOC__
          ~msg:("same number of messages in " ^ level_str)
          num_msgs
          (List.length block.content.messages) ;
        Helpers.Assert.State_hash.equal
          ~loc:__LOC__
          ~msg:("state hash match after fuel eval in " ^ level_str)
          res_state_hash
          expected_state_hash ;
        Assert.Int32.equal
          ~loc:__LOC__
          ~msg:("inbox level ok in " ^ level_str)
          (Raw_level.to_int32 level)
          (Raw_level.to_int32 block.header.level) ;
        return state)
      genesis_state
      blocks
  in
  return_unit

let eval_messages_fuel_test kind node_ctxt =
  let module PVM = (val Components.pvm_of_kind kind) in
  let module Fueled = Fueled_pvm.Make (PVM) in
  let open Lwt_result_syntax in
  let* genesis, blocks = build_chain node_ctxt ~length:30 in
  let*! genesis_ctxt =
    Context.checkout node_ctxt.context genesis.header.context
  in
  let genesis_ctxt = WithExceptions.Option.get ~loc:__LOC__ genesis_ctxt in
  let*! genesis_state = PVM.State.find genesis_ctxt in
  let genesis_state = WithExceptions.Option.get ~loc:__LOC__ genesis_state in
  let num_ticks_of_messages node_ctxt state inbox_level messages =
    let parts =
      List.fold_left
        (fun acc msg -> [msg] :: List.map (List.cons msg) acc)
        []
        (List.rev messages)
    in
    let+ results =
      List.fold_left_es
        (fun acc messages ->
          let* res =
            Fueled.Free.eval_messages
              ~fuel:(Fuel.Free.of_ticks 0L)
              node_ctxt
              ~message_counter_offset:0
              state
              inbox_level
              messages
          in
          let+ res =
            Tezos_layer2_store.Delayed_write_monad.apply node_ctxt res
          in
          (res, messages) :: acc)
        []
        parts
    in
    List.rev results
  in
  let check_ticks_of_messages node_ctxt state inbox_level messages
      messages_ticks ~interval =
    let nb_messages = List.length messages in
    List.fold_left_es
      (fun (pred_state, total_ticks, pred_messages)
           ( {Fueled.Free.state = expected_state; num_ticks = expected_ticks; _},
             part ) ->
        let part_size = List.length part in
        if part_size mod interval = 0 || part_size = nb_messages then (
          let new_messages = list_diff messages pred_messages in
          let allowed_ticks = Z.(expected_ticks - total_ticks |> to_int64) in
          let fuel = Fuel.Accounted.of_ticks allowed_ticks in
          let* res =
            Fueled.Accounted.eval_messages
              ~fuel
              node_ctxt
              ~message_counter_offset:(List.length pred_messages)
              pred_state
              inbox_level
              new_messages
          in
          let* res =
            Tezos_layer2_store.Delayed_write_monad.apply node_ctxt res
          in
          let*! state_hash = PVM.state_hash res.state in
          let*! expected_state_hash = PVM.state_hash expected_state in
          let*! state_tick = PVM.get_tick res.state in
          let*! expected_state_tick = PVM.get_tick expected_state in
          let where =
            Format.sprintf
              " in level %ld at message %d with interval %d"
              (Raw_level.to_int32 inbox_level)
              part_size
              interval
          in
          Assert.Int.Option.equal
            ~loc:__LOC__
            ~msg:("ticks match after fuel eval" ^ where)
            (Sc_rollup.Tick.to_int state_tick)
            (Sc_rollup.Tick.to_int expected_state_tick) ;
          Helpers.Assert.State_hash.equal
            ~loc:__LOC__
            ~msg:("state hash match after fuel eval" ^ where)
            state_hash
            expected_state_hash ;
          return (res.state, Z.(total_ticks + res.num_ticks), part))
        else return (pred_state, total_ticks, pred_messages))
      (state, Z.zero, [])
      messages_ticks
  in
  let* (_ : PVM.state) =
    List.fold_left_es
      (fun pred_state (block : Sc_rollup_block.t) ->
        let* block =
          Node_context.get_full_l2_block node_ctxt block.header.block_hash
        in
        let*! ctxt = Context.checkout node_ctxt.context block.header.context in
        let ctxt = WithExceptions.Option.get ~loc:__LOC__ ctxt in
        let*! state = PVM.State.find ctxt in
        let state = WithExceptions.Option.get ~loc:__LOC__ state in
        let* messages_ticks =
          num_ticks_of_messages
            node_ctxt
            pred_state
            block.header.level
            block.content.messages
        in
        let* () =
          List.iter_es
            (fun interval ->
              let* res_state, _res_num_ticks, res_messages =
                check_ticks_of_messages
                  node_ctxt
                  pred_state
                  block.header.level
                  block.content.messages
                  messages_ticks
                  ~interval
              in
              let*! res_state_hash = PVM.state_hash res_state in
              let*! expected_state_hash = PVM.state_hash state in
              let level_str =
                Raw_level.to_int32 block.header.level |> Int32.to_string
              in
              Assert.Int.equal
                ~loc:__LOC__
                ~msg:("same number of messages in " ^ level_str)
                (List.length res_messages)
                (List.length block.content.messages) ;
              Helpers.Assert.State_hash.equal
                ~loc:__LOC__
                ~msg:
                  ("state hash match after iterative fuel eval in " ^ level_str)
                res_state_hash
                expected_state_hash ;
              return_unit)
            (range 1 (List.length block.content.messages))
        in
        return state)
      genesis_state
      blocks
  in
  return_unit

let tests =
  [
    Helpers.alcotest
      "fueled eval block (arith)"
      `Quick
      Sc_rollup.Kind.Example_arith
      (eval_block_fuel_test Example_arith);
    Helpers.alcotest
      "fueled eval block (wasm)"
      `Quick
      Sc_rollup.Kind.Wasm_2_0_0
      (eval_block_fuel_test Wasm_2_0_0);
    Helpers.alcotest
      "fueled eval message (arith)"
      `Quick
      Sc_rollup.Kind.Example_arith
      (eval_messages_fuel_test Example_arith);
    Helpers.alcotest
      "fueled eval message (wasm)"
      `Quick
      Sc_rollup.Kind.Wasm_2_0_0
      (eval_messages_fuel_test Wasm_2_0_0);
  ]

let () =
  Alcotest_lwt.run "fueled_eval" [(Protocol.name ^ ": fueled_eval", tests)]
  |> Lwt_main.run
