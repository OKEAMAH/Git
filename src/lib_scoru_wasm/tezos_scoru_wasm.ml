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

let ( let*! ) = Lwt.bind

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

type compute_step_kont =
  | CS_Parsing of Tezos_webassembly_interpreter.Decode.decode_kont
  | CS_Runtime of Tezos_webassembly_interpreter.Ast.module_'
  | CS_Error

let compute_step_kont_encoding =
  let open Data_encoding in
  union
    [
      case
        ~title:"boot_sequence"
        (Tag 0)
        (obj2
           (req "kind" @@ constant "boot_sequence")
           (req "value" Kont_encodings.decode_kont))
        (function CS_Parsing kont -> Some ((), kont) | _ -> None)
        (fun ((), kont) -> CS_Parsing kont);
      case
        ~title:"runtime"
        (Tag 1)
        (obj2
           (req "kind" (constant "runtime"))
           (req "ast" Ast_encoding.module_encoding'))
        (function CS_Runtime m -> Some ((), m) | _ -> None)
        (fun ((), m) -> CS_Runtime m);
      case
        ~title:"error"
        (Tag 2)
        (obj1 (req "kind" @@ constant "error"))
        (function CS_Error -> Some () | _ -> None)
        (fun () -> CS_Error);
    ]

module Make (T : TreeS) : sig
  (** [boot ctxt boot_sector] initializes the PVM with a given [boot_sector]. *)
  val boot : T.t -> string -> T.tree Lwt.t

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

  module Thunk = Thunk.Make (Tree)

  (* TODO: Should not be [string], but chunked data *)
  type state =
    string (* wasm-version *)
    * (string (* boot sector *) * string (* next kernel *))
    * compute_step_kont (* label for [compute_step] *)
    * int (* persistent state of [compute_step] *)

  let state_schema : state Thunk.schema =
    let open Thunk.Schema in
    obj4
      (req "wasm-version" @@ encoding Data_encoding.string)
      (req "durable" @@ folders ["kernel"]
      @@ obj2
           (req "boot.wasm" @@ encoding Data_encoding.string)
           (req "next" @@ encoding Data_encoding.string))
      (req "label" @@ encoding compute_step_kont_encoding)
      (req "counter" @@ encoding Data_encoding.int31)

  let version_l = Thunk.tup4_0

  let boot_l = Thunk.(tup4_1 ^. tup2_0)

  let _next_boot_l = Thunk.(tup4_1 ^. tup2_1)

  let label_l = Thunk.tup4_2

  let counter_l = Thunk.tup4_3

  let boot : T.t -> string -> T.tree Lwt.t =
   fun ctxt boot_sector ->
    let aux =
      let open Lwt_result.Syntax in
      let open Thunk.Syntax in
      let tree = T.empty ctxt in
      let thunk = Thunk.decode state_schema tree in
      let* () = (thunk ^-> version_l) ^:= "2.0.0" in
      let* () = (thunk ^-> boot_l) ^:= boot_sector in
      let* () =
        (thunk ^-> label_l)
        ^:= CS_Parsing (D_Start {name = "boot.wasm"; input = boot_sector})
      in
      let*! tree = Thunk.encode tree thunk in
      Lwt_result.return tree
    in
    let open Lwt.Syntax in
    let* aux = aux in
    match aux with Ok tree -> Lwt.return tree | Error _ -> assert false

  let incr_counter state_t =
    let open Thunk.Syntax in
    let*^? cpt = state_t ^-> counter_l in
    (state_t ^-> counter_l) ^:= (Option.value ~default:0 cpt + 1)

  let step :
      state Thunk.t -> compute_step_kont -> compute_step_kont Thunk.result Lwt.t
      =
   fun state_t ->
    let open Lwt_result.Syntax in
    function
    | CS_Parsing (D_Result res) ->
        let* () = incr_counter state_t in
        Lwt_result.return (CS_Runtime res.it)
    | CS_Parsing kont ->
        let* () = incr_counter state_t in
        let kont =
          try CS_Parsing (Tezos_webassembly_interpreter.Decode.decode_step kont)
          with _ -> CS_Error
        in
        Lwt_result.return kont
    | CS_Runtime modules ->
        let* () = incr_counter state_t in
        Lwt_result.return (CS_Runtime modules)
    | CS_Error ->
        let* () = incr_counter state_t in
        Lwt_result.return CS_Error

  let compute_step tree =
    let aux state_t =
      let open Lwt_result.Syntax in
      let open Thunk.Syntax in
      let*^ kont = state_t ^-> label_l in
      let* kont' = step state_t kont in
      (state_t ^-> label_l) ^:= kont'
    in

    let open Lwt.Syntax in
    let state_t = Thunk.decode state_schema tree in
    let* x = aux state_t in
    match x with
    | Ok () -> Thunk.encode tree state_t
    | Error _ ->
        (* If our PVM implementation is correct, this never happens *)
        assert false

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

module Encoding = struct
  module Kont = Kont_encodings
end
