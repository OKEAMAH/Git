(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2022 Nomadic Labs, <contact@nomadic-labs.com>               *)
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

open Store_sigs

module Make (N : sig
  val name : string
end) =
struct
  module Maker = Irmin_pack_unix.Maker (Tezos_context_encoding.Context.Conf)
  include Maker.Make (Tezos_context_encoding.Context.Schema)
  module Schema = Tezos_context_encoding.Context.Schema

  let make_key_path path key = path @ [key]

  type nonrec +'a t = t

  let load : type a. a mode -> string -> a t Lwt.t =
   fun mode data_dir ->
    let open Lwt_syntax in
    let readonly = match mode with Read_only -> true | Read_write -> false in
    let* repo = Repo.v (Irmin_pack.config ~readonly data_dir) in
    main repo

  let flush store = flush (repo store)

  let close store = Repo.close (repo store)

  let info message =
    let date =
      Tezos_base.Time.(
        System.now () |> System.to_protocol |> Protocol.to_seconds)
    in
    Irmin.Info.Default.v ~author:N.name ~message date

  let path_to_string path = String.concat "/" path

  let set_exn store path bytes =
    let full_path = path_to_string path in
    let info () = info full_path in
    set_exn ~info store path bytes

  let readonly = Fun.id

  let export ?path store =
    let open Lwt_syntax in
    let* root_key =
      let open Lwt_option_syntax in
      let*! t = tree store in
      let*! t =
        match path with
        | None -> Lwt.return t
        | Some path -> (
            let open Lwt_syntax in
            let+ t = Tree.find_tree t path in
            match t with
            | None -> Stdlib.failwith ("No such tree /" ^ String.concat "/" path)
            | Some t -> t)
      in
      let*? key = Tree.key t in
      return key
    in
    let total_size = ref 0 in
    let root_key = WithExceptions.Option.get ~loc:__LOC__ root_key in
    let+ r =
      Snapshot.export (repo store) ~root_key @@ function
      | Blob contents ->
          let s = Bytes.length contents in
          total_size := !total_size + s ;
          (* Format.eprintf "Blob : %d B@." s ; *)
          return_unit
      | Inode _ -> return_unit
      (* {v; root = _} -> ( *)
      (* match v with *)
      (* | Inode_tree {depth; length; pointers = _} -> *)
      (*     Format.eprintf "Inode: depth %d Len %d@." depth length ; *)
      (*     return_unit *)
      (* | Inode_value entries -> *)
      (*     List.iter *)
      (*       (fun {Snapshot.step; hash = _} -> *)
      (*         Format.eprintf "Step : %S@." step) *)
      (*       entries ; *)
      (*     return_unit) *)
    in
    let p = match path with None -> "" | Some p -> String.concat "/" p in
    Format.eprintf "/%s: Total size: %d@." p !total_size ;
    r
end
