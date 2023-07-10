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

include Tezos_scoru_wasm.Wasm_pvm_state

type reveal = Reveal_raw_data of reveal_hash | Reveal_metadata

(** Represents the state of input requests. *)
type input_request =
  | No_input_required  (** The VM does not expect any input. *)
  | Input_required  (** The VM needs input in order to progress. *)
  | Reveal_required of reveal

(** Represents the state of the VM. *)
type info = {
  current_tick : Z.t;
      (** The number of ticks processed by the VM, zero for the initial state.
          [current_tick] must be incremented for each call to [step] *)
  last_input_read : input_info option;
      (** The last message to be read by the VM, if any. *)
  input_request : input_request;  (** The current VM input request. *)
}

let from_reveal : Tezos_webassembly_interpreter.Host_funcs.reveal -> reveal =
  function
  | Reveal_raw_data hash -> Reveal_raw_data hash
  | Reveal_metadata -> Reveal_metadata
  | Reveal_dal _ ->
      (* FIXME: We should justify why it can't happen. *)
      assert false

let to_reveal : reveal -> Tezos_webassembly_interpreter.Host_funcs.reveal =
 fun _ -> assert false

let from_input_request :
    Tezos_scoru_wasm.Wasm_pvm_state.input_request -> input_request = function
  | No_input_required -> No_input_required
  | Input_required -> Input_required
  | Reveal_required reveal -> Reveal_required (from_reveal reveal)

let to_input_request :
    input_request -> Tezos_scoru_wasm.Wasm_pvm_state.input_request =
 fun _ -> assert false

let from_info : Tezos_scoru_wasm.Wasm_pvm_state.info -> info =
 fun {current_tick; last_input_read; input_request} ->
  {
    current_tick;
    last_input_read;
    input_request = from_input_request input_request;
  }

let to_info : info -> Tezos_scoru_wasm.Wasm_pvm_state.info =
 fun _ -> assert false

module Make (T : Tezos_tree_encoding.TREE) = struct
  include Tezos_scoru_wasm.Wasm_pvm.Make (T)

  let get_info tree =
    let open Tezos_error_monad.Error_monad.Lwt_syntax in
    let* info = get_info tree in
    return (from_info info)
end
