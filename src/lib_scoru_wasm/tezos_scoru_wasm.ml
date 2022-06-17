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

  (* FIXME: naming of module *)
  module Decoding = Tree_decoding.Make(T)

  (* Status internal to the PVM 
   *
   * From the outside the PVM is either computing or waiting for input. The internal 
   * status also includes _what_ is done with the input we are expecting - loading a
   * kernel or waiting for input to a running kernel; and what kind of computation is
   * running - parsing a kernel image or executing a kernel.
   *)
  type internal_status = Parsing | Computing | WaitingForInput | GatheringFloppies

  (* The key to the storage tree where the _internal_ status is stored *)
  let internal_status_key = ["pvm"; "status"]

  (* Decodes the status as it is stored in the tree *)
  let internal_status_encoding = failwith "Not implemented yet - how does Data_encoding module work?"

  let get_status = 
    Decoding.(run (value internal_status_key internal_status_encoding))
   
  type initial_boot_pk = string

  let initial_boot_pk_encoding = 
    failwith "Not implemented yet - Data_encoding again"

  let initial_boot_pk_key = ["pvm"; "public_key"]

  let get_initial_boot_pk =
    Decoding.(run (value initial_boot_pk_key initial_boot_pk_encoding))

  let kernel_image_key = ["pvm"; "kernel_image"]

  let store_kernel_image_chunk chunk =
    failwith "Not implemented yet"
    
  let kernel_loading_step i chunk = 
    (* TODO:
     * If(origination-chunk and we have written no other chunks)
     * then store public_key and store chunk
     * else check signature and store chunk
     *)
    failwith "Not implemented"

  let compute_step = Lwt.return

  let set_input_step i chunk t = (* Lwt.return - no more *)
    Lwt.bind (get_status t) (fun status ->
        match status with 
        | GatheringFloppies -> kernel_loading_step i chunk
        | Parsing -> failwith "Not implemented"
        | Computing -> failwith "Not implemented"
        | WaitingForInput -> failwith "Not implemented")
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
