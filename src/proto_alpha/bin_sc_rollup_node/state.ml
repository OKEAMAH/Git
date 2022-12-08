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

let hash_of_level =
  let max_cached = 1023 in
  let module Cache =
    Aches_lwt.Lache.Make_option
      (Aches.Rache.Transfer
         (Aches.Rache.LRU)
         (struct
           include Int32

           let hash = to_int
         end)) in
  let cache = Cache.create max_cached in
  fun (cctxt : Protocol_client_context.full) level ->
    let open Lwt_syntax in
    let get_level_hash level =
      let+ hash =
        Tezos_shell_services.Shell_services.Blocks.hash
          cctxt
          ~chain:cctxt#chain
          ~block:(`Level level)
          ()
      in
      Result.to_option hash
    in
    Cache.bind_or_put cache level get_level_hash @@ function
    | None -> failwith "Cannot retrieve hash of level %ld" level
    | Some h -> Lwt_result.return h

let level_of_hash l1_ctxt hash =
  let open Lwt_result_syntax in
  let+ {level; _} = Layer1.fetch_tezos_shell_header l1_ctxt hash in
  level

let mark_processed_head store Layer1.{hash; level} =
  let open Lwt_result_syntax in
  let* () = Store.Processed_blocks.add store.Store.processed_blocks hash () in
  Store.Head.write store.last_processed_head (hash, level)

let is_processed store head =
  Store.Processed_blocks.mem store.Store.processed_blocks head

let last_processed_head_opt store =
  let open Lwt_result_syntax in
  let+ res = Store.Head.read store.Store.last_processed_head in
  Option.map (fun (hash, level) -> Layer1.{hash; level}) res

let mark_finalized_head store Layer1.{hash; level} =
  Store.Head.write store.Store.last_finalized_head (hash, level)

let get_finalized_head_opt store =
  let open Lwt_result_syntax in
  let+ res = Store.Head.read store.Store.last_finalized_head in
  Option.map (fun (hash, level) -> Layer1.{hash; level}) res
