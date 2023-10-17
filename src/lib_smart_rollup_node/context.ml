(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2021 Nomadic Labs, <contact@nomadic-labs.com>               *)
(* Copyright (c) 2023 Marigold <contact@marigold.dev>                        *)
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

open Store_sigs
module Context_encoding = Tezos_context_encoding.Context_binary

(* We shadow [Tezos_context_encoding] to prevent accidentally using
   [Tezos_context_encoding.Context] instead of
   [Tezos_context_encoding.Context_binary] during a future
   refactoring.*)
module Tezos_context_encoding = struct end

type error +=
  | Unexpected_rollup of {
      rollup_address : Octez_smart_rollup.Address.t;
      saved_address : Octez_smart_rollup.Address.t;
    }

let () =
  register_error_kind
    ~id:"sc_rollup.node.unexpected_rollup"
    ~title:"Unexpected rollup for rollup node"
    ~description:"This rollup node is already set up for another rollup."
    ~pp:(fun ppf (rollup_address, saved_address) ->
      Format.fprintf
        ppf
        "This rollup node was already set up for rollup %a, it cannot be run \
         for a different rollup %a."
        Octez_smart_rollup.Address.pp
        saved_address
        Octez_smart_rollup.Address.pp
        rollup_address)
    `Permanent
    Data_encoding.(
      obj2
        (req "rollup_address" Octez_smart_rollup.Address.encoding)
        (req "saved_address" Octez_smart_rollup.Address.encoding))
    (function
      | Unexpected_rollup {rollup_address; saved_address} ->
          Some (rollup_address, saved_address)
      | _ -> None)
    (fun (rollup_address, saved_address) ->
      Unexpected_rollup {rollup_address; saved_address})

module Maker = Irmin_pack_unix.Maker (Context_encoding.Conf)

module IStore = struct
  include Maker.Make (Context_encoding.Schema)
  module Schema = Context_encoding.Schema
end

module IStoreTree =
  Tezos_context_helpers.Context.Make_tree (Context_encoding.Conf) (IStore)

type tree = IStore.tree

type 'a raw_index = {path : string; repo : IStore.Repo.t}

type 'a index = 'a raw_index constraint 'a = [< `Read | `Write > `Read]

type rw_index = [`Read | `Write] index

type ro_index = [`Read] index

type 'a t = {index : 'a index; tree : tree}

type rw = [`Read | `Write] t

type ro = [`Read] t

type commit = IStore.commit

type hash = Smart_rollup_context_hash.t

type path = string list

let () = assert (Smart_rollup_context_hash.size = IStore.Hash.hash_size)

let hash_to_istore_hash h =
  Smart_rollup_context_hash.to_string h |> IStore.Hash.unsafe_of_raw_string

let istore_hash_to_hash h =
  IStore.Hash.to_raw_string h |> Smart_rollup_context_hash.of_string_exn

let load : type a. cache_size:int -> a mode -> string -> a raw_index Lwt.t =
 fun ~cache_size mode path ->
  let open Lwt_syntax in
  let readonly = match mode with Read_only -> true | Read_write -> false in
  let+ repo =
    IStore.Repo.v
      (Irmin_pack.config
         ~readonly
           (* Note that the use of GC in the context requires that
            * the [always] indexing strategy not be used. *)
         ~indexing_strategy:Irmin_pack.Indexing_strategy.minimal
         ~lru_size:cache_size
         path)
  in
  {path; repo}

let close ctxt = IStore.Repo.close ctxt.repo

let readonly (index : [> `Read] index) = (index :> [`Read] index)

let raw_commit ?(message = "") index tree =
  let info = IStore.Info.v ~author:"Tezos" 0L ~message in
  IStore.Commit.v index.repo ~info ~parents:[] tree

let commit ?message ctxt =
  let open Lwt_syntax in
  let+ commit = raw_commit ?message ctxt.index ctxt.tree in
  IStore.Commit.hash commit |> istore_hash_to_hash

let checkout index key =
  let open Lwt_syntax in
  let* o = IStore.Commit.of_hash index.repo (hash_to_istore_hash key) in
  match o with
  | None -> return_none
  | Some commit ->
      let tree = IStore.Commit.tree commit in
      return_some {index; tree}

let empty index = {index; tree = IStore.Tree.empty ()}

let is_empty ctxt = IStore.Tree.is_empty ctxt.tree

(* adapted from lib_context/disk/context.ml *)
let gc index ?(callback : unit -> unit Lwt.t = fun () -> Lwt.return ())
    (hash : hash) =
  let open Lwt_syntax in
  let repo = index.repo in
  let istore_hash = hash_to_istore_hash hash in
  let* commit_opt = IStore.Commit.of_hash index.repo istore_hash in
  match commit_opt with
  | None ->
      Fmt.failwith "%a: unknown context hash" Smart_rollup_context_hash.pp hash
  | Some commit -> (
      let finished = function
        | Ok (stats : Irmin_pack_unix.Stats.Latest_gc.stats) ->
            let total_duration =
              Irmin_pack_unix.Stats.Latest_gc.total_duration stats
            in
            let finalise_duration =
              Irmin_pack_unix.Stats.Latest_gc.finalise_duration stats
            in
            let* () = callback () in
            Event.ending_context_gc
              ( Time.System.Span.of_seconds_exn total_duration,
                Time.System.Span.of_seconds_exn finalise_duration )
        | Error (`Msg err) -> Event.context_gc_failure err
      in
      let commit_key = IStore.Commit.key commit in
      let* launch_result = IStore.Gc.run ~finished repo commit_key in
      match launch_result with
      | Error (`Msg err) -> Event.context_gc_launch_failure err
      | Ok false -> Event.context_gc_already_launched ()
      | Ok true -> Event.starting_context_gc hash)

let wait_gc_completion index =
  let open Lwt_syntax in
  let* r = IStore.Gc.wait index.repo in
  match r with
  | Ok _stats_opt -> return_unit
  | Error (`Msg _msg) ->
      (* Logs will be printed by the [gc] caller. *)
      return_unit

let is_gc_finished index = IStore.Gc.is_finished index.repo

let index context = context.index

module Proof (Hash : sig
  type t

  val of_context_hash : Context_hash.t -> t
end) (Proof_encoding : sig
  val proof_encoding :
    Tezos_context_sigs.Context.Proof_types.tree
    Tezos_context_sigs.Context.Proof_types.t
    Data_encoding.t
end) =
struct
  module IStoreProof =
    Tezos_context_helpers.Context.Make_proof (IStore) (Context_encoding.Conf)

  module Tree = struct
    include IStoreTree

    type t = rw_index

    type tree = IStore.tree

    type key = path

    type value = bytes
  end

  type tree = Tree.tree

  type proof = IStoreProof.Proof.tree IStoreProof.Proof.t

  let hash_tree tree = Hash.of_context_hash (Tree.hash tree)

  let proof_encoding = Proof_encoding.proof_encoding

  let proof_before proof =
    let (`Value hash | `Node hash) = proof.IStoreProof.Proof.before in
    Hash.of_context_hash hash

  let proof_after proof =
    let (`Value hash | `Node hash) = proof.IStoreProof.Proof.after in
    Hash.of_context_hash hash

  let produce_proof index tree step =
    let open Lwt_syntax in
    (* Committing the context is required by Irmin to produce valid proofs. *)
    let* _commit_key = raw_commit index tree in
    match Tree.kinded_key tree with
    | Some k ->
        let* p = IStoreProof.produce_tree_proof index.repo k step in
        return_some p
    | None -> return_none

  let verify_proof proof step =
    (* The rollup node is not supposed to verify proof. We keep
       this part in case this changes in the future. *)
    let open Lwt_syntax in
    let* result = IStoreProof.verify_tree_proof proof step in
    match result with
    | Ok v -> return_some v
    | Error _ ->
        (* We skip the error analysis here since proof verification is not a
           job for the rollup node. *)
        return_none
end

(** State of the PVM that this rollup node deals with. *)
module PVMState = struct
  type value = tree

  let key = ["pvm_state"]

  let empty () = IStore.Tree.empty ()

  let find ctxt = IStore.Tree.find_tree ctxt.tree key

  let lookup tree path = IStore.Tree.find tree path

  let set ctxt state =
    let open Lwt_syntax in
    let+ tree = IStore.Tree.add_tree ctxt.tree key state in
    {ctxt with tree}
end

module Rollup = struct
  let path = ["rollup_address"]

  let set_address (index : rw_index) addr =
    let open Lwt_result_syntax in
    protect @@ fun () ->
    let info () =
      let date =
        Time.(System.now () |> System.to_protocol |> Protocol.to_seconds)
      in
      IStore.Info.v date
    in
    let value =
      Data_encoding.Binary.to_bytes_exn Octez_smart_rollup.Address.encoding addr
    in
    let*! store = IStore.main index.repo in
    let*! () = IStore.set_exn ~info store path value in
    return_unit

  let get_address (index : _ raw_index) =
    let open Lwt_result_syntax in
    protect @@ fun () ->
    let*! store = IStore.main index.repo in
    let*! value = IStore.find store path in
    return
    @@ Option.map
         (Data_encoding.Binary.of_bytes_exn Octez_smart_rollup.Address.encoding)
         value

  let check_or_set_address (type a) (mode : a mode) (index : a raw_index)
      rollup_address =
    let open Lwt_result_syntax in
    let* saved_address = get_address index in
    match saved_address with
    | Some saved_address ->
        fail_unless Octez_smart_rollup.Address.(rollup_address = saved_address)
        @@ Unexpected_rollup {rollup_address; saved_address}
    | None -> (
        (* Address was never saved, we set it permanently if not in read-only
           mode. *)
        match mode with
        | Store_sigs.Read_only -> return_unit
        | Read_write -> set_address index rollup_address)
end

module Version = struct
  type t = V0

  let version = V0

  let encoding =
    let open Data_encoding in
    conv
      (fun V0 -> 0)
      (function
        | 0 -> V0
        | v ->
            Format.ksprintf Stdlib.failwith "Unsupported context version %d" v)
      int31

  let path = ["context_version"]

  let set (index : rw_index) =
    let open Lwt_result_syntax in
    protect @@ fun () ->
    let info () =
      let date =
        Time.(System.now () |> System.to_protocol |> Protocol.to_seconds)
      in
      IStore.Info.v date
    in
    let value = Data_encoding.Binary.to_bytes_exn encoding version in
    let*! store = IStore.main index.repo in
    let*! () = IStore.set_exn ~info store path value in
    return_unit

  let get (index : _ index) =
    let open Lwt_result_syntax in
    protect @@ fun () ->
    let*! store = IStore.main index.repo in
    let*! value = IStore.find store path in
    return @@ Option.map (Data_encoding.Binary.of_bytes_exn encoding) value

  let check (index : _ index) =
    let open Lwt_result_syntax in
    let* context_version = get index in
    match context_version with None | Some V0 -> return_unit

  let check_and_set (index : _ index) =
    let open Lwt_result_syntax in
    let* context_version = get index in
    match context_version with None -> set index | Some V0 -> return_unit
end

let load :
    type a. cache_size:int -> a mode -> string -> a raw_index tzresult Lwt.t =
 fun ~cache_size mode path ->
  let open Lwt_result_syntax in
  let*! index = load ~cache_size mode path in
  let+ () =
    match mode with
    | Read_only -> Version.check index
    | Read_write -> Version.check_and_set index
  in
  index

module Internal_for_tests = struct
  let get_a_tree key =
    let tree = IStore.Tree.empty () in
    IStore.Tree.add tree [key] Bytes.empty
end
