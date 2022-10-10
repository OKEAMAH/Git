(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2022 Nomadic Labs <contact@nomadic-labs.com>                *)
(* Copyright (c) 2022 Trili Tech, <contact@trili.tech>                       *)
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
    Component:    Rollup layer 1 logic
    Invocation:   dune exec \
                  src/proto_alpha/lib_protocol/test/unit/main.exe \
                  -- test "^\[Unit\] sc rollup wasm$"
    Subject:      Unit test for the Wasm PVM
*)

open Protocol
open Tezos_micheline.Micheline
open Michelson_v1_primitives
open Tezos_scoru_wasm
module Context = Tezos_context_memory.Context_binary
include Tezos_tree_encoding

(** copied from Tezt.Base*)
let project_root =
  match Sys.getenv_opt "DUNE_SOURCEROOT" with
  | Some x -> x
  | None -> (
      match Sys.getenv_opt "PWD" with
      | Some x -> x
      | None ->
          (* For some reason, under [dune runtest], [PWD] and
             [getcwd] have different values. [getcwd] is in
             [_build/default], and [PWD] is where [dune runtest] was
             executed, which is closer to what we want. *)
          Sys.getcwd ())

let read_file filename =
  let ch = open_in filename in
  let s = really_input_string ch (in_channel_length ch) in
  close_in ch ;
  s

module Proof_encoding =
  Tezos_context_merkle_proof_encoding.Merkle_proof_encoding

module Wasm_context = struct
  module Tree = struct
    include Context.Tree

    type tree = Context.tree

    type t = Context.t

    type key = string list

    type value = bytes
  end

  type tree = Context.tree

  type proof = Context.Proof.tree Context.Proof.t

  let verify_proof p f =
    Lwt.map Result.to_option (Context.verify_tree_proof p f)

  let produce_proof context tree step =
    let open Lwt_syntax in
    let* context = Context.add_tree context [] tree in
    let* _hash = Context.commit ~time:Time.Protocol.epoch context in
    let index = Context.index context in
    match Context.Tree.kinded_key tree with
    | Some k ->
        let* p = Context.produce_tree_proof index k step in
        return (Some p)
    | None -> return None

  let kinded_hash_to_state_hash = function
    | `Value hash | `Node hash ->
        Sc_rollup_repr.State_hash.context_hash_to_state_hash hash

  let proof_before proof = kinded_hash_to_state_hash proof.Context.Proof.before

  let proof_after proof = kinded_hash_to_state_hash proof.Context.Proof.after

  let proof_encoding = Proof_encoding.V2.Tree32.tree_proof_encoding
end

module Full_Wasm =
  Sc_rollup_wasm.V2_0_0.Make (Environment.Wasm_2_0_0.Make) (Wasm_context)

type Tezos_lazy_containers.Lazy_map.tree += Tree of Context.tree

module Tree = struct
  type t = Context.t

  type tree = Context.tree

  type key = Context.key

  type value = Context.value

  include Context.Tree

  let select = function
    | Tree t -> t
    | _ -> raise Tezos_tree_encoding.Incorrect_tree_type

  let wrap t = Tree t
end

module Wasm = Wasm_pvm.Make (Tree)

let set_input_step message message_counter tree =
  let input_info =
    Wasm_pvm_sig.
      {
        inbox_level =
          Option.value_f ~default:(fun () -> assert false)
          @@ Tezos_base.Bounded.Non_negative_int32.of_value 0l;
        message_counter = Z.of_int message_counter;
      }
  in
  Wasm.set_input_step input_info message tree

let rec eval_until_input_requested ?(max_steps = 5000L) tree =
  let open Lwt_syntax in
  let* info = Wasm.get_info tree in
  match info.input_request with
  | No_input_required ->
      let* tree = Wasm.compute_step_many ~max_steps tree in
      eval_until_input_requested ~max_steps tree
  | Input_required -> return tree
  | Reveal_required _ -> return tree

let read_binary name =
  let kernel_file =
    project_root ^ "/src/lib_scoru_wasm/test/wasm_kernels/" ^ name
  in
  read_file kernel_file

let pipe_kernel = read_binary "pipe.wasm"

let test_initial_state_hash_wasm_pvm () =
  let open Lwt_result_syntax in
  let open Alpha_context in
  let context = Tezos_context_memory.make_empty_context () in
  let*! state = Sc_rollup_helpers.Wasm_pvm.initial_state context in
  let*! hash = Sc_rollup_helpers.Wasm_pvm.state_hash state in
  let expected = Sc_rollup.Wasm_2_0_0PVM.reference_initial_state_hash in
  if Sc_rollup.State_hash.(hash = expected) then return_unit
  else
    failwith
      "incorrect hash, expected %a, got %a"
      Sc_rollup.State_hash.pp
      expected
      Sc_rollup.State_hash.pp
      hash

let test_incomplete_kernel_chunk_limit () =
  let open Lwt_result_syntax in
  let operator =
    match Account.generate_accounts 1 with
    | [(account, _, _)] -> account
    | _ -> assert false
  in
  let chunk_size = Tezos_scoru_wasm.Gather_floppies.chunk_size in
  let chunk_too_big = Bytes.make (chunk_size + 10) 'a' in
  let signature = Signature.sign operator.Account.sk chunk_too_big in
  let floppy =
    Tezos_scoru_wasm.Gather_floppies.{chunk = chunk_too_big; signature}
  in
  match
    Data_encoding.Binary.to_string_opt
      Tezos_scoru_wasm.Gather_floppies.floppy_encoding
      floppy
  with
  | None -> return_unit
  | Some _ -> failwith "encoding of a floppy with a chunk too large should fail"

let make_transaction value text contract =
  let entrypoint = Entrypoint_repr.default in
  let destination : Contract_hash.t =
    Contract_hash.of_bytes_exn @@ Bytes.of_string contract
  in
  let unparsed_parameters =
    strip_locations
    @@ Prim
         ( 0,
           I_TICKET,
           [Prim (0, I_PAIR, [Int (0, Z.of_int32 value); String (1, text)], [])],
           [] )
  in
  Sc_rollup_outbox_message_repr.{unparsed_parameters; entrypoint; destination}

let make_transactions () =
  let l =
    [
      QCheck2.Gen.(
        generate1
          (triple (string_size @@ return 20) int32 (small_string ~gen:char)));
    ]
  in
  List.map (fun (contract, i, s) -> make_transaction i s contract) l

let test_output () =
  let open Lwt_result_syntax in
  let*! dummy = Context.init "/tmp" in
  let dummy_context = Context.empty dummy in
  let empty_tree : Wasm.tree = Tree.empty dummy_context in
  let boot_sector =
    Data_encoding.Binary.to_string_exn
      Gather_floppies.origination_message_encoding
      (Gather_floppies.Complete_kernel (String.to_bytes pipe_kernel))
  in
  let*! tree =
    Wasm.Internal_for_tests.initial_tree_from_boot_sector
      ~empty_tree
      boot_sector
  in
  let*! tree =
    Wasm.Internal_for_tests.set_max_nb_ticks (Z.of_int64 50_000_000L) tree
  in
  let*! tree = eval_until_input_requested tree in
  let transactions = make_transactions () in
  let out =
    Sc_rollup_outbox_message_repr.(Atomic_transaction_batch {transactions})
  in
  let withdrawal =
    Data_encoding.Binary.to_string_exn
      Sc_rollup_outbox_message_repr.encoding
      out
  in
  let*! tree = set_input_step withdrawal 0 tree in
  let*! final_tree = eval_until_input_requested tree in
  let*! output = Wasm.Internal_for_tests.get_output_buffer final_tree in
  let*! level, message_index =
    Tezos_webassembly_interpreter.Output_buffer.get_id output
  in
  let*! bytes =
    Tezos_webassembly_interpreter.Output_buffer.get output level message_index
  in
  let message =
    Data_encoding.Binary.of_bytes_exn
      Sc_rollup_outbox_message_repr.encoding
      bytes
  in
  assert (message = out) ;
  let*? outbox_level =
    Environment.wrap_tzresult @@ Raw_level_repr.of_int32 level
  in
  let output = Sc_rollup_PVM_sig.{outbox_level; message_index; message} in

  let*! pf = Full_Wasm.produce_output_proof dummy_context final_tree output in

  match pf with
  | Ok proof ->
      let*! valid = Full_Wasm.verify_output_proof proof in
      fail_unless valid (Exn (Failure "An output proof is not valid."))
  | Error _ -> failwith "Error during proof generation"

let tests =
  [
    Tztest.tztest
      "initial state hash for Wasm"
      `Quick
      test_initial_state_hash_wasm_pvm;
    Tztest.tztest
      "encoding of a floppy with a chunk too large should fail"
      `Quick
      test_incomplete_kernel_chunk_limit;
    Tztest.tztest "test output proofs" `Quick test_output;
  ]
