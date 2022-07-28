(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
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

open Tezos_webassembly_interpreter

type tick_state = Decode of Decode.decode_kont | Eval of Eval.config

type pvm_state = {
  kernel : Chunked_byte_vector.Lwt.t;
  current_tick : Z.t;
  last_input_info : Wasm_pvm_sig.input_info option;
  consuming : bool;
  (* TODO: Remove the field as soon as we know how to implement
     [waiting_for_input : Eval.config -> bool] *)
  tick : tick_state;
}

module Make (T : Tree.S) : Gather_floppies.S with type tree = T.tree = struct
  module Raw = struct
    type tree = T.tree

    module Wasm = Tezos_webassembly_interpreter
    module EncDec =
      Tree_encoding_decoding.Make (Wasm.Instance.NameMap) (Wasm.Instance.Vector)
        (Wasm.Chunked_byte_vector.Lwt)
        (T)
    module Wasm_encoding = Wasm_encoding.Make (EncDec)

    let decode_kont : Decode.decode_kont EncDec.t = assert false

    let config : Eval.config EncDec.t = assert false

    let tick_state : tick_state EncDec.t =
      let open EncDec in
      tagged_union
        (value [] Data_encoding.string)
        [
          case
            "decode"
            decode_kont
            (function Decode k -> Some k | _ -> None)
            (fun k -> Decode k);
          case
            "eval"
            config
            (function Eval c -> Some c | _ -> None)
            (fun c -> Eval c);
        ]

    let pvm_state : pvm_state EncDec.t =
      let open EncDec in
      conv
        (fun (current_tick, kernel, last_input_info, consuming, tick) ->
          {current_tick; kernel; last_input_info; consuming; tick})
        (fun {current_tick; kernel; last_input_info; consuming; tick} ->
          (current_tick, kernel, last_input_info, consuming, tick))
        (tup5
           ~flatten:true
           (value ~default:Z.zero ["wasm"; "current_tick"] Data_encoding.n)
           (scope ["durable"; "kernel"; "boot.wasm"] chunked_byte_vector)
           (optional ["wasm"; "input"] Wasm_pvm_sig.input_info_encoding)
           (value ~default:true ["wasm"; "consuming"] Data_encoding.bool)
           (scope ["wasm"] tick_state))

    let compute_step state =
      let open Lwt_syntax in
      match state.tick with
      | Decode k -> (
          let* k = Decode.module_step state.stream k in
          match k.module_kont with
          | Decode.MKStop m ->
              (* Decoding phase is done, moving on to eval *)
              (* TODO: https://gitlab.com/tezos/tezos/-/issues/3076
                 Rather than doing one big tick, we should tickify
                 [Eval.init] *)
              let minst = Eval.init _ m _ in
              assert false
          | _ ->
              (* Decoding still progressing *)
              {state with tick = Decode k})
      | _ -> _

    let compute_step tree =
      let open Lwt_syntax in
      let* state = EncDec.decode pvm_state tree in
      let state = {state with current_tick = Z.succ state.current_tick} in
      EncDec.encode pvm_state state tree

    let get_output _ _ = Lwt.return ""

    (* TODO: #3448
       Remove the mention of exceptions from lib_scoru_wasm Make signature.
       Add try_with or similar to catch exceptions and put the machine in a
       stuck state instead. https://gitlab.com/tezos/tezos/-/issues/3448
    *)

    let get_info tree =
      let open Lwt_syntax in
      let+ state = EncDec.decode pvm_state tree in
      Wasm_pvm_sig.
        {
          current_tick = state.current_tick;
          last_input_read = state.last_input_info;
          input_request =
            (if state.consuming then Input_required else No_input_required);
        }

    let set_input_step input_info _message tree =
      let open Lwt_syntax in
      let* state = EncDec.decode pvm_state tree in
      let state =
        {
          state with
          last_input_info = Some input_info;
          current_tick = Z.succ state.current_tick;
        }
      in
      EncDec.encode pvm_state state tree
  end

  include Gather_floppies.Make (T) (Raw)
end
