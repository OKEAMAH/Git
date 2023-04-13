(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2023 Nomadic Labs <contact@nomadic-labs.com>                *)
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

(* Invocation: dune exec -- tezt/tests/main.exe --file tezos_scoru_wasm_regressions.ml *)

open Tezos_scoru_wasm_helpers
open Tezos_scoru_wasm_helpers.Wasm_utils

(* Helpers *)
module Context_binary = Tezos_context_memory.Context_binary

module Prover = struct
  open Tezos_protocol_alpha
  open Tezos_protocol_alpha.Protocol

  module Tree :
    Environment.Context.TREE
      with type t = Context_binary.t
       and type tree = Context_binary.tree
       and type key = string list
       and type value = bytes = struct
    type t = Context_binary.t

    type tree = Context_binary.tree

    type key = Context_binary.key

    type value = Context_binary.value

    include Context_binary.Tree
  end

  module WASM_P :
    Alpha_context.Sc_rollup.Wasm_2_0_0PVM.P
      with type Tree.t = Context_binary.t
       and type Tree.tree = Context_binary.tree
       and type Tree.key = string list
       and type Tree.value = bytes
       and type proof = Context_binary.Proof.tree Context_binary.Proof.t =
  struct
    open Alpha_context
    module Tree = Tree

    type tree = Tree.tree

    type proof = Context_binary.Proof.tree Context_binary.Proof.t

    let proof_encoding =
      Tezos_context_merkle_proof_encoding.Merkle_proof_encoding.V2.Tree2
      .tree_proof_encoding

    let kinded_hash_to_state_hash :
        Context_binary.Proof.kinded_hash -> Sc_rollup.State_hash.t = function
      | `Value hash | `Node hash ->
          Sc_rollup.State_hash.context_hash_to_state_hash hash

    let proof_before proof =
      kinded_hash_to_state_hash proof.Context_binary.Proof.before

    let proof_after proof =
      kinded_hash_to_state_hash proof.Context_binary.Proof.after

    let produce_proof context tree step =
      let open Lwt_syntax in
      let* context = Context_binary.add_tree context [] tree in
      let* (_hash : Context_hash.t) =
        Context_binary.commit ~time:Time.Protocol.epoch context
      in
      let index = Context_binary.index context in
      match Context_binary.Tree.kinded_key tree with
      | Some k ->
          let* p = Context_binary.produce_tree_proof index k step in
          return (Some p)
      | None ->
          Stdlib.failwith
            "produce_proof: internal error, [kinded_key] returned [None]"

    let verify_proof proof step =
      let open Lwt_syntax in
      let* result = Context_binary.verify_tree_proof proof step in
      match result with
      | Ok v -> return (Some v)
      | Error _ ->
          (* We skip the error analysis here since proof verification is not a
             job for the rollup node. *)
          return None
  end

  include
    Alpha_context.Sc_rollup.Wasm_2_0_0PVM.Make
      (Environment.Wasm_2_0_0.Make)
      (WASM_P)
end

module Verifier =
  Tezos_protocol_alpha.Protocol.Alpha_context.Sc_rollup.Wasm_2_0_0PVM
  .Protocol_implementation

let version_name = function Wasm_pvm_state.V0 -> "v0" | V1 -> "v1"

let capture_hash_of tree =
  Regression.capture @@ Context_hash.to_b58check
  @@ Encodings_util.Tree.hash tree

let rec eval_and_capture_many ?(fail_on_stuck = true) ~bunk
    ?(max_steps = Int64.max_int) tree =
  capture_hash_of tree ;
  let* info = Wasm_fast.get_info tree in
  match info.input_request with
  | No_input_required when max_steps > 0L ->
      let steps = Int64.min bunk max_steps in
      let* tree, steps = Wasm_fast.compute_step_many ~max_steps:steps tree in
      let max_steps = Int64.sub max_steps steps in
      eval_and_capture_many ~bunk ~max_steps tree
  | _ ->
      let* is_stuck = Wasm_fast.Internal_for_tests.is_stuck tree in
      if fail_on_stuck && Option.is_some is_stuck then
        Test.fail ~__LOC__ "WASM PVM is stuck" ;
      return tree

let echo_kernel =
  read_file
  @@ project_root // "src" // "proto_alpha" // "lib_protocol" // "test"
     // "integration" // "wasm_kernel" // "echo.wast"

let tx_no_verify_kernel =
  read_file
  @@ project_root // "src" // "lib_scoru_wasm" // "test" // "wasm_kernels"
     // "tx-kernel-no-verif.wasm"

let tx_no_verify_inputs =
  let base =
    project_root // "src" // "lib_scoru_wasm" // "test" // "messages"
  in
  [read_file (base // "deposit.out"); read_file (base // "withdrawal.out")]

let link_kernel import_name import_params import_results =
  Format.sprintf
    {|
(module
 (import "smart_rollup_core" "%s"
         (func $%s (param %s) (result %s)))
 (memory 1)
 (export "mem" (memory 0))
 (func (export "kernel_run")
    (nop)))
  |}
    import_name
    import_name
    (String.concat " " import_params)
    (String.concat " " import_results)

let check_proof_size ~current_tick ~proof_size_limit context input_opt s =
  let open Lwt_syntax in
  let* proof = Prover.produce_proof context input_opt s in
  match proof with
  | Error _ ->
      Test.fail "Could not compute proof for tick %a" Z.pp_print current_tick
  | Ok proof ->
      let bytes =
        Data_encoding.Binary.to_bytes_exn Prover.proof_encoding proof
      in
      let len = Bytes.length bytes in
      if proof_size_limit < Bytes.length bytes then
        Test.fail
          "Found a proof too large (%d bytes) at tick %a"
          len
          Z.pp_print
          current_tick ;
      Regression.capture Format.(asprintf "%a, %d" Z.pp_print current_tick len) ;
      unit

let checked_eval ~proof_size_limit context s =
  let open Lwt_syntax in
  let* info = Wasm_fast.get_info s in
  let* () =
    check_proof_size
      ~current_tick:info.current_tick
      ~proof_size_limit
      context
      None
      s
  in
  unit

let context ~name () =
  let open Lwt_syntax in
  let* index = Context_binary.init name in
  return (Context_binary.empty index)

let register_gen ~from_binary ~fail_on_stuck ?ticks_per_snapshot ~tag ~inputs
    ~skip_ticks ~ticks_to_check ~name ~versions k kernel =
  let eval context s =
    let rec eval checked_ticks s =
      let* info = Wasm_fast.get_info s in
      match info.input_request with
      | No_input_required when checked_ticks < ticks_to_check ->
          let* () = k context s in
          let* s = Wasm_fast.compute_step s in
          (eval [@tailcall]) Int64.(succ checked_ticks) s
      | No_input_required -> (skip [@tailcall]) s
      | _ -> return s
    and skip s =
      let* info = Wasm_fast.get_info s in
      match info.input_request with
      | No_input_required when 0L < skip_ticks ->
          let* s, _ = Wasm_fast.compute_step_many ~max_steps:skip_ticks s in
          (eval [@tailcall]) 0L s
      | No_input_required -> (eval [@tailcall]) 0L s
      | _ -> return s
    in
    eval 0L s
  in

  List.iter
    (fun version ->
      Regression.register
        ~__FILE__
        ~title:
          Format.(
            sprintf "kernel %s run (%s, %s)" name tag (version_name version))
        ~tags:["wasm_2_0_0"; name; tag; version_name version]
        (fun () ->
          let* context = context ~name () in
          let* tree =
            initial_tree ~from_binary ~version ?ticks_per_snapshot kernel
          in
          let* tree = set_full_input_step inputs 0l tree in
          let* tree = eval context tree in
          let* is_stuck = Wasm_fast.Internal_for_tests.is_stuck tree in
          if Option.is_some is_stuck && fail_on_stuck then
            Test.fail "Evaluation reached a Stuck state" ;
          unit))
    versions

let register ?(from_binary = false) ?(fail_on_stuck = true) ?ticks_per_snapshot
    ?(inputs = []) ?(proof_size_limit = 16 * 1024) ?hash_frequency
    ?proof_frequency ~name ~versions kernel =
  (match proof_frequency with
  | Some proof_frequency ->
      register_gen
        ~tag:"proof"
        ~from_binary
        ~fail_on_stuck
        ?ticks_per_snapshot
        ~inputs
        ~versions
        ~name
        ~skip_ticks:(snd proof_frequency)
        ~ticks_to_check:(fst proof_frequency)
        (fun context s -> checked_eval ~proof_size_limit context s)
        kernel
  | None -> ()) ;
  match hash_frequency with
  | Some hash_frequency ->
      register_gen
        ~tag:"hash"
        ~from_binary
        ~fail_on_stuck
        ?ticks_per_snapshot
        ~inputs
        ~versions
        ~name
        ~skip_ticks:hash_frequency
        ~ticks_to_check:1L
        (fun _ s ->
          capture_hash_of s ;
          unit)
        kernel
  | None -> ()

module HostFunctionsDiffs = Set.Make (struct
  type t = string * string list * string list

  let compare (n, params, res) (n', params', res') =
    let compare_ty = List.compare String.compare in
    match String.compare n n' with
    | 0 -> (
        match compare_ty params params' with 0 -> compare_ty res res' | n -> n)
    | n -> n
end)

let extract_type_from_extern =
  let module TzWasm = Tezos_webassembly_interpreter in
  function
  | TzWasm.Instance.ExternFunc
      (TzWasm.Func.HostFunc (FuncType (params, res), _)) ->
      let* params =
        Tezos_lazy_containers.Lazy_vector.Int32Vector.to_list params
      in
      let* res = Tezos_lazy_containers.Lazy_vector.Int32Vector.to_list res in
      Lwt.return_some
        ( List.map TzWasm.Types.string_of_value_type params,
          List.map TzWasm.Types.string_of_value_type res )
  | _ -> Lwt.return_none

let version_to_string version =
  List.assoc ~equal:( = ) version Wasm_pvm_state.versions_flip
  |> Option.value ~default:"unknown version"

let generate_host_functions_diff v_current v_next =
  let module TzWasm = Tezos_webassembly_interpreter in
  let host_funcs_per_version version =
    let registry = Host_funcs.registry ~version ~write_debug:Builtins.Noop in
    TzWasm.Host_funcs.defined_host_functions registry
  in
  (* Finds the type of a host function following this pattern: if the host
     function doesn't exists in the new version of the registry, it means it has
     been removed and we check for it in the previous one. *)
  let get_ty name =
    let kind =
      Host_funcs.Internal_for_tests.host_function_from_registry_name name
      |> Option.value_f ~default:(fun () ->
             Stdlib.failwith
               (name
              ^ " has no defined kind in `Tezos_scoru_wasm.Host_funcs`, the \
                 associated host function is probably not accessible"))
    in
    let extern =
      match
        Host_funcs.Internal_for_tests.lookup_host_function ~version:v_next kind
      with
      | Some e -> Some e
      | None ->
          Host_funcs.Internal_for_tests.lookup_host_function
            ~version:v_current
            kind
    in
    let* types =
      Option.fold_s ~some:extract_type_from_extern ~none:None extern
    in
    match types with
    | Some (params, res) -> return (params, res)
    | None ->
        (* Note that if the diff has been computed correctly, this case is
           impossible. *)
        Stdlib.failwith
          (Format.sprintf
             "%s definition not found neither in registry for %s nor %s."
             name
             (version_to_string v_current)
             (version_to_string v_next))
  in

  let current = host_funcs_per_version v_current |> String_set.of_list in
  let next = host_funcs_per_version v_next |> String_set.of_list in
  let hf_diff =
    String_set.(union (diff current next) (diff next current))
    |> String_set.to_seq
  in
  Seq.S.fold_left
    (fun map name ->
      let* params, res = get_ty name in
      return (HostFunctionsDiffs.add (name, params, res) map))
    HostFunctionsDiffs.empty
    hf_diff

let build_version_diffs () =
  let get_next_version = function
    | Wasm_pvm_state.V0 -> Some Wasm_pvm_state.V1
    | V1 -> None
  in
  let rec build acc version =
    match get_next_version version with
    | None -> List.rev acc
    | Some next_version -> build ((version, next_version) :: acc) next_version
  in
  build [] V0

let register_host_functions_diff (current_version, next_version) =
  let* diff = generate_host_functions_diff current_version next_version in
  let register (name, params, res) =
    let name =
      let tag = "link_" ^ name in
      if String.length tag > 32 then String.sub tag 0 32 else tag
    in
    register
      ~name
      ~fail_on_stuck:false
      ~from_binary:false
      ~ticks_per_snapshot:5_000L
      ~inputs:tx_no_verify_inputs
      ~versions:[current_version; next_version]
      ~hash_frequency:0L
      ~proof_frequency:(1L, 0L)
      (link_kernel name params res)
  in
  HostFunctionsDiffs.iter register diff ;
  Lwt.return_unit

let build_version_regression_diffs () =
  let versions = build_version_diffs () in
  List.iter_s register_host_functions_diff versions

let register () =
  register
    ~name:"echo"
    ~from_binary:false
    ~ticks_per_snapshot:5_000L
    ~inputs:[]
    ~versions:[V0; V1]
    ~hash_frequency:137L
    ~proof_frequency:(11L, 23L)
    echo_kernel ;
  register
    ~name:"tx_no_verify"
    ~from_binary:true
    ~ticks_per_snapshot:6_000_000L
    ~inputs:tx_no_verify_inputs
    ~versions:[V0; V1]
    ~hash_frequency:10_037L
    ~proof_frequency:(3L, 30_893L)
    tx_no_verify_kernel ;
  (* Register all the changes of host host functions tests. *)
  Lwt_main.run (build_version_regression_diffs ())
