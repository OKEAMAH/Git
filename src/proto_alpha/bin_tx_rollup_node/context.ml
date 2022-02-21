(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2022 Nomadic Labs, <contact@nomadic-labs.com>               *)
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

open Protocol.Tx_rollup_l2_storage_sig
open Error
open Context_encoding

(* /!\ Logging and parameters copied over from [lib_context/context.ml].
  TODO/TORU: check them.
*)

let reporter () =
  let report src level ~over k msgf =
    let k _ =
      over () ;
      k ()
    in
    let with_stamp h _tags k fmt =
      let dt = Mtime.Span.to_us (Mtime_clock.elapsed ()) in
      Fmt.kpf
        k
        Fmt.stderr
        ("%+04.0fus %a %a @[" ^^ fmt ^^ "@]@.")
        dt
        Fmt.(styled `Magenta string)
        (Logs.Src.name src)
        Logs_fmt.pp_header
        (level, h)
    in
    msgf @@ fun ?header ?tags fmt -> with_stamp header tags k fmt
  in
  {Logs.report}

(* Caps the number of entries stored in the Irmin's index. As a
   trade-off, increasing this value will delay index merges, and thus,
   make them more expensive in terms of disk usage, memory usage and
   computation time.*)
let index_log_size = ref 2_500_000

(* Caps the number of entries stored in the Irmin's LRU cache. As a
   trade-off, increasing this value will increase the memory
   consumption.*)
let lru_size = ref 5_000

let () =
  let verbose_info () =
    Logs.set_level (Some Logs.Info) ;
    Logs.set_reporter (reporter ())
  in
  let verbose_debug () =
    Logs.set_level (Some Logs.Debug) ;
    Logs.set_reporter (reporter ())
  in
  let index_log_size n = index_log_size := int_of_string n in
  let lru_size n = lru_size := int_of_string n in
  match Sys.getenv_opt "TEZOS_TX_ROLLUP_CONTEXT" with
  | None -> ()
  | Some v ->
      let args = String.split ',' v in
      List.iter
        (function
          | "v" | "verbose" -> verbose_info ()
          | "vv" -> verbose_debug ()
          | v -> (
              match String.split '=' v with
              | ["index-log-size"; n] -> index_log_size n
              | ["lru-size"; n] -> lru_size n
              | _ ->
                  Format.eprintf
                    "Warning: unknown content %S for environment variable \
                     TEZOS_TX_ROLLUP_CONTEXT@."
                    v))
        args

(* Build a Tx rollup context with binary trees *)
(* TODO/TORU: https://gitlab.com/tezos/tezos/-/issues/2540
   Use V2 when possible. *)
module Store =
  Irmin_pack.Make_ext (Irmin_pack.Version.V1) (Conf) (Node) (Commit) (Metadata)
    (Contents)
    (Path)
    (Branch)
    (Hash)
module P = Store.Private

(* TODO/TORU: https://gitlab.com/tezos/tezos/-/issues/2541
   Provide an in-memory context for tests. *)

type index = {
  path : string;
  repo : Store.Repo.t;
  patch_context : (context -> context tzresult Lwt.t) option;
  readonly : bool;
}

and context = {index : index; parents : Store.Commit.t list; tree : Store.tree}

let index {index; _} = index

module Irmin_storage :
  STORAGE with type t = context and type 'a m = 'a tzresult Lwt.t = struct
  type t = context

  type 'a m = 'a tzresult Lwt.t

  let path k = [Bytes.to_string k]

  let get (ctxt : context) key : bytes option m =
    let open Lwt_result_syntax in
    let*! res = Store.Tree.find ctxt.tree (path key) in
    return res

  let set ctxt key value =
    let open Lwt_result_syntax in
    let*! tree = Store.Tree.add ctxt.tree (path key) value in
    return {ctxt with tree}

  module Syntax = struct
    include Lwt_result_syntax

    let catch m k h =
      m >>= function
      | Ok x -> k x
      | Error (Environment.Ecoproto_error e :: _) -> h e
      | Error err ->
          (* TODO/TORU: replace error either in STORAGE or here *)
          (* Should not happen *)
          fail err

    let fail e =
      let e = Environment.wrap_tzerror e in
      Lwt.return (Error [e])

    let list_fold_left_m = List.fold_left_es
  end
end

include Protocol.Tx_rollup_l2_context.Make (Irmin_storage)

let empty index = {index; parents = []; tree = Store.Tree.empty ()}

let sync index =
  if index.readonly then Store.sync index.repo ;
  Lwt.return ()

let exists index key =
  let open Lwt_syntax in
  let* () = sync index in
  let+ o = Store.Commit.of_hash index.repo (Hash.of_context_hash key) in
  Option.is_some o

let checkout index key =
  let open Lwt_syntax in
  let* () = sync index in
  let* o = Store.Commit.of_hash index.repo (Hash.of_context_hash key) in
  match o with
  | None -> return_none
  | Some commit ->
      let tree = Store.Commit.tree commit in
      return_some {index; tree; parents = [commit]}

let checkout_exn index key =
  let open Lwt_syntax in
  let* o = checkout index key in
  match o with None -> Lwt.fail Not_found | Some p -> Lwt.return p

(* unshallow possible 1-st level objects from previous partial
   checkouts ; might be better to pass directly the list of shallow
   objects. *)
let unshallow context =
  let open Lwt_syntax in
  let* children = Store.Tree.list context.tree [] in
  P.Repo.batch context.index.repo (fun contents node _ ->
      List.iter_s
        (fun (name, child_tree) ->
          match Store.Tree.destruct child_tree with
          | `Contents _ -> Lwt.return ()
          | `Node _ ->
              let* tree = Store.Tree.get_tree context.tree [name] in
              let+ _ =
                Store.save_tree
                  ~clear:true
                  context.index.repo
                  contents
                  node
                  tree
              in
              ())
        children)

(* Version 0 hardcoded now *)

let get_hash_version _c = Protocol.Tx_rollup_l2_context_hash.Version.of_int 0

let set_hash_version c v =
  let expected = Protocol.Tx_rollup_l2_context_hash.Version.(of_int 0) in
  if Protocol.Tx_rollup_l2_context_hash.Version.(expected = v) then return c
  else fail (Tx_rollup_unsupported_context_version {expected; current = v})

let raw_commit ?(message = "") context =
  let open Lwt_syntax in
  let info = Info.v ~author:"Tezos_tx_rollup" ~date:0L message in
  let parents = List.map Store.Commit.hash context.parents in
  let* () = unshallow context in
  let+ c = Store.Commit.v context.index.repo ~info ~parents context.tree in
  Store.Tree.clear context.tree ;
  c

let hash ?(message = "") context =
  let info = Info.v ~author:"Tezos_tx_rollup" ~date:0L message in
  let parents = List.map (fun c -> Store.Commit.hash c) context.parents in
  let node = Store.Tree.hash context.tree in
  let commit = P.Commit.Val.v ~parents ~node ~info in
  let x = P.Commit.Key.hash commit in
  Hash.to_context_hash x

let commit ?message context =
  let open Lwt_syntax in
  let+ commit = raw_commit ?message context in
  Hash.to_context_hash (Store.Commit.hash commit)

let init ?patch_context ?(readonly = false) root =
  let open Lwt_syntax in
  let+ repo =
    Store.Repo.v
      (Irmin_pack.config
         ~readonly
         ~index_log_size:!index_log_size
         ~lru_size:!lru_size
         root)
  in
  {path = root; repo; patch_context; readonly}

let close index = Store.Repo.close index.repo
