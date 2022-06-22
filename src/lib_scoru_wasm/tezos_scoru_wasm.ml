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

(*

  This library acts as a dependency to the protocol environment. Everything that
  must be exposed to the protocol via the environment shall be added here.

*)

open Sigs

type input = {
  inbox_level : Tezos_base.Bounded.Int32.NonNegative.t;
  message_counter : Z.t;
}

type output = {
  outbox_level : Tezos_base.Bounded.Int32.NonNegative.t;
  message_index : Z.t;
}

type input_request = No_input_required | Input_required

type info = {
  current_tick : Z.t;
      (** The number of ticks processed by the VM, zero for the initial state.

      [current_tick] must be incremented for each call to [step] *)
  last_input_read : input option;
      (** The last message to be read by the VM, if any. *)
  input_request : input_request;  (** The current VM input request. *)
}

module Make (T : TreeS) : sig
  (** [compute_step] forwards the VM by one compute tick.

      If the VM is expecting input, it gets stuck.

      If the VM is already stuck, this function may raise an exception. *)
  val compute_step : T.tree -> T.tree Lwt.t

  (** [set_input_step] forwards the VM by one input tick.

      If the VM is not expecting input, it gets stuck.

      If the VM is already stuck, this function may raise an exception. *)
  val set_input_step : input -> string -> T.tree -> T.tree Lwt.t

  (** [get_output output state] returns the payload associated with the given output.

      The result is meant to be deserialized using [Sc_rollup_PVM_sem.output_encoding].

      If the output is missing, this function may raise an exception.
      *)
  val get_output : output -> T.tree -> string Lwt.t

  (** [get_info] provides a typed view of the current machine state.

      Should not raise. *)
  val get_info : T.tree -> info Lwt.t
end = struct
  module Tree = struct
    include T
  end

  type compute_step_kont = CS_Boot_sequence | CS_Runtime | CS_Fatal_error

  let compute_step_kont_encoding =
    let open Data_encoding in
    union
      [
        case
          ~title:"boot_sequence"
          (Tag 0)
          (constant "boot_sequence")
          (function CS_Boot_sequence -> Some () | _ -> None)
          (fun () -> CS_Boot_sequence);
        case
          ~title:"runtime"
          (Tag 1)
          (constant "runtime")
          (function CS_Runtime -> Some () | _ -> None)
          (fun () -> CS_Runtime);
        case
          ~title:"fatal_error"
          (Tag 2)
          (constant "fatal_error")
          (function CS_Fatal_error -> Some () | _ -> None)
          (fun () -> CS_Fatal_error);
      ]

  module Thunk = Thunk.Make (Tree)

  (* TODO: Should not be [string], but chunked data *)
  type state = (string * string) * compute_step_kont * int

  let state_schema : state Thunk.schema =
    let open Thunk.Schema in
    obj3
      (req "durable" @@ folders ["kernel"]
      @@ obj2
           (req "boot.wasm" @@ encoding Data_encoding.string)
           (req "next" @@ encoding Data_encoding.string))
      (req "label" @@ encoding compute_step_kont_encoding)
      (req "counter" @@ encoding Data_encoding.int31)

  let _boot_l = Thunk.(tup3_0 ^. tup2_0)

  let _next_boot_l = Thunk.(tup3_0 ^. tup2_1)

  let label_l = Thunk.tup3_1

  let counter_l = Thunk.tup3_2

  let step :
      int Thunk.t -> compute_step_kont -> compute_step_kont Thunk.result Lwt.t =
   fun state ->
    let open Lwt_result.Syntax in
    function
    | CS_Boot_sequence ->
        let* () = Thunk.set state 0 in
        Lwt_result.return CS_Runtime
    | CS_Runtime ->
        let* x = Thunk.get state in
        let* () = Thunk.set state (x + 1) in
        Lwt_result.return CS_Runtime
    | CS_Fatal_error ->
        (* If [Thunk] is implemented correctly, this should not happen *)
        Lwt_result.return CS_Fatal_error

  let ( let*! ) = Lwt.bind

  let compute_step tree =
    let aux state_t =
      let open Lwt_result.Syntax in
      let* kont_t = label_l state_t in
      let* kont = Thunk.get kont_t in
      let* payload_t = counter_l state_t in
      let*! res = step payload_t kont in
      match res with
      | Ok label' -> Thunk.set kont_t label'
      | Error _ -> Thunk.set kont_t CS_Fatal_error
    in

    let open Lwt.Syntax in
    let state_t = Thunk.decode state_schema tree in
    let* _ = aux state_t in
    Thunk.encode tree state_t

  let set_input_step _ _ = Lwt.return
  (* TODO: https://gitlab.com/tezos/tezos/-/issues/3092

     Implement handling of input logic.
  *)

  let get_output _ _ = Lwt.return ""

  let get_info _ =
    Lwt.return
      {
        current_tick = Z.of_int 0;
        last_input_read = None;
        input_request = No_input_required;
      }
end
