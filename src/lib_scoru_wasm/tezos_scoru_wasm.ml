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

exception Malformed_origination_message

exception Malformed_inbox_message

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


  val kernel_loading_step : string -> T.tree -> T.tree Lwt.t
end = struct
  module Tree = struct
    include T
  end

  module Decoding = Tree_decoding.Make(Tree)

  
  (* Update/set value in tree *)

  let update_set key value t = 
    Lwt.return t (* TODO *)

  (* TYPES *)

  (* From the outside the PVM is either computing or waiting for input. The internal 
   * status also includes _what_ is done with the input we are expecting - loading a
   * kernel or waiting for input to a running kernel; and what kind of computation is
   * running - parsing a kernel image or executing a kernel.  *)
  type internal_status = Parsing | Computing | WaitingForInput | GatheringFloppies

  (* The public key that is included in the initial (origination) operation
   * that created the rollup in case the origination operation contained an
   * in-complete kernel image. The rest of the kernel image chunks must be 
   * signed with this key.  *)
  type initial_boot_pk = bytes

  (* Each chunk of the kernel image needs a signature matching the public key 
   * included in the origination message - so that not just anyone can add 
   * arbitrary chunks to the kernel image. *)
  type kernel_image_signature = bytes

  (* The first message containing the kernel image. In case the whole kernel 
   * fits (less than 32kb in size) it is a `CompleteKernel`. Otherwise we'll 
   * also need a public key to check signatures of the following kernel image
   * chunks. *)
  type origination_message = 
    | CompleteKernel of bytes 
    | InCompleteKernel of bytes * initial_boot_pk

  (* The following messages containing the kernel image. Each chunk must be
   * signed (validate with public key in origination message). *)
  type inbox_kernel_message = InboxKernelMessage of bytes * kernel_image_signature 

  (* STORAGE KEYS *)

  (* The key to the storage tree where the _internal_ status is stored *)
  let internal_status_key = ["pvm"; "status"]

  (* Where the initial boot public key is stored in the tree *)
  let initial_boot_pk_key = ["pvm"; "public_key"]

  (* Where the chunks are stored *)
  let kernel_image_chunks_key = ["pvm"; "kernel_image"]

  (* ENCODINGS *)

  (* Decodes the status as it is stored in the tree *)
  let internal_status_encoding = 
    let open Data_encoding in 
    union [
      case 
        ~title:"parsing"
        (Tag 0)
        unit
        (function Parsing -> Some () | _ -> None)
        (fun () -> Parsing);
      case 
        ~title:"computing"
        (Tag 1)
        unit
        (function Computing -> Some () | _ -> None)
        (fun () -> Computing);
      case
        ~title:"waiting for input"
        (Tag 2)
        unit
        (function WaitingForInput -> Some () | _ -> None)
        (fun () -> WaitingForInput);
      case
        ~title:"gathering floppies"
        (Tag 3)
        unit
        (function GatheringFloppies -> Some () | _ -> None)
        (fun () -> GatheringFloppies)
    ]

  let initial_boot_pk_encoding = Data_encoding.bytes

  let origination_message_encoding = 
    failwith "not implemented"

  let inbox_kernel_message_encoding =
    failwith "not implemented"

  (* STORAGE/TREE INTERACTION *)

  let get_internal_status = 
    Decoding.(run (value internal_status_key internal_status_encoding))
   
  let set_internal_status v t =
    update_set internal_status_key v t

  (* Get the initial boot public key from the tree *)
  let get_initial_boot_pk =
    Decoding.(run (value initial_boot_pk_key initial_boot_pk_encoding))

  let set_initial_boot_pk =
    update_set initial_boot_pk_key

  let store_kernel_image_chunk chunk t =
    failwith "Not implemented yet"
    
  (* PROCESS MESSAGES *)

  (* Process and store the kernel image in the origination message
   * This message contains either the entire (small) kernel image or the first
   * chunk of it. *)
  let origination_kernel_loading_step message t = 
    match Data_encoding.Binary.of_string origination_message_encoding message with
    | Error error -> raise Malformed_origination_message
    | Ok (CompleteKernel chunk) -> Lwt.Syntax.(
        let* t2 = store_kernel_image_chunk chunk t in
        set_internal_status Parsing t2)
    | Ok (InCompleteKernel (chunk, boot_pk)) -> Lwt.Syntax.(
        let* t2 = store_kernel_image_chunk chunk t in
        let* t3 = set_initial_boot_pk boot_pk t2 in
        set_internal_status GatheringFloppies t3)

  (* Process sub-sequent kernel image chunks. If the chunk has zero length it 
   * means we're done and we have the entire kernel image. *)
  let kernel_loading_step message t = 
    match Data_encoding.Binary.of_string inbox_kernel_message_encoding message with
    | Error error -> raise Malformed_inbox_message
    | Ok (InboxKernelMessage (chunk, _signature)) -> 
      if Bytes.length chunk = 0
      then set_internal_status Parsing t
      else store_kernel_image_chunk chunk t

  let compute_step = Lwt.return

  let set_input_step i chunk t = Lwt.return t
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
