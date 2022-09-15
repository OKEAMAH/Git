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

open Protocol_client_context

type signer = {
  alias : string;
  pkh : Signature.public_key_hash;
  pk : Signature.public_key;
  sk : Client_keys.sk_uri;
}

let get_signer cctxt pkh =
  let open Lwt_result_syntax in
  let* alias, pk, sk = Client_keys.get_key cctxt pkh in
  return {alias; pkh; pk; sk}

type 'block reorg = {old_chain : 'block list; new_chain : 'block list}

let no_reorg = {old_chain = []; new_chain = []}

let reorg_encoding block_encoding =
  let open Data_encoding in
  conv
    (fun {old_chain; new_chain} -> (old_chain, new_chain))
    (fun (old_chain, new_chain) -> {old_chain; new_chain})
  @@ obj2
       (req "old_chain" (list block_encoding))
       (req "new_chain" (list block_encoding))

let fetch_tezos_block ~find_in_cache (cctxt : #full) hash rpc =
  let open Lwt_syntax in
  let errors = ref None in
  let fetch hash =
    let* block = rpc cctxt cctxt#chain (`Hash (hash, 0)) in
    match block with
    | Error errs ->
        errors := Some errs ;
        return_none
    | Ok block -> return_some block
  in
  let+ block = find_in_cache hash fetch in
  match (block, !errors) with
  | None, None ->
      (* This should not happen if {!find_in_cache} behaves correctly,
         i.e. calls {!fetch} for cache misses. *)
      error_with
        "Fetching Tezos block %a failed unexpectedly"
        Block_hash.pp
        hash
  | None, Some errs -> Error errs
  | Some block, _ -> Ok block

let fetch_tezos_header ~find_in_cache (cctxt : #full) hash =
  fetch_tezos_block ~find_in_cache (cctxt : #full) hash
  @@ fun cctxt chain block ->
  Tezos_shell_services.Shell_services.Blocks.Header.shell_header
    cctxt
    ~chain
    ~block
    ()

let fetch_tezos_block ~find_in_cache (cctxt : #full) hash =
  fetch_tezos_block ~find_in_cache (cctxt : #full) hash
  @@ fun cctxt chain block ->
  Alpha_block_services.info cctxt ~chain ~block ~metadata:`Always ()

(* Compute the reorganization of L1 blocks from the chain whose head is
   [old_head_hash] and the chain whose head [new_head_hash]. *)
let tezos_reorg fetch_tezos_block get_shell_header ~old_head_hash ~new_head_hash
    =
  let open Lwt_result_syntax in
  let rec loop old_chain new_chain old_head_hash new_head_hash =
    if Block_hash.(old_head_hash = new_head_hash) then
      return {old_chain = List.rev old_chain; new_chain = List.rev new_chain}
    else
      let* new_head = fetch_tezos_block new_head_hash in
      let* old_head = fetch_tezos_block old_head_hash in
      let old_header : Block_header.shell_header = get_shell_header old_head in
      let new_header : Block_header.shell_header = get_shell_header new_head in
      let old_level = old_header.level in
      let new_level = new_header.level in
      let diff = Int32.sub new_level old_level in
      let old_chain, new_chain, old, new_ =
        if diff = 0l then
          (* Heads at same level *)
          let new_chain = new_head_hash :: new_chain in
          let old_chain = old_head_hash :: old_chain in
          let new_head_hash = new_header.predecessor in
          let old_head_hash = old_header.predecessor in
          (old_chain, new_chain, old_head_hash, new_head_hash)
        else if diff > 0l then
          (* New chain is longer *)
          let new_chain = new_head_hash :: new_chain in
          let new_head_hash = new_header.predecessor in
          (old_chain, new_chain, old_head_hash, new_head_hash)
        else
          (* Old chain was longer *)
          let old_chain = old_head_hash :: old_chain in
          let old_head_hash = old_header.predecessor in
          (old_chain, new_chain, old_head_hash, new_head_hash)
      in
      loop old_chain new_chain old new_
  in
  loop [] [] old_head_hash new_head_hash
