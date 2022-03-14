(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2022 Nomadic Labs <contact@nomadic-labs.com>                *)
(* Copyright (c) 2022 Oxhead Alpha <info@oxheadalpha.com>                    *)
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

module Verifier_storage :
  Tx_rollup_l2_storage_sig.STORAGE
    with type t = Context.tree
     and type 'a m = ('a, error) result Lwt.t = struct
  type t = Context.tree

  type 'a m = ('a, error) result Lwt.t

  module Syntax = struct
    let ( let* ) = ( >>=? )

    let ( let+ ) = ( >|=? )

    let return = return

    let fail e = Lwt.return (Error e)

    let catch (m : 'a m) k h = m >>= function Ok x -> k x | Error e -> h e

    let list_fold_left_m = List.fold_left_es
  end

  let path k = [Bytes.to_string k]

  let get store key = Context.Tree.find store (path key) >>= return

  let set store key value = Context.Tree.add store (path key) value >>= return

  let remove store key = Context.Tree.remove store (path key) >>= return
end

module Verifier_context = Tx_rollup_l2_context.Make (Verifier_storage)
module Verifier_apply = Tx_rollup_l2_apply.Make (Verifier_context)

let verify_proof message proof
    ~(agreed : Alpha_context.Tx_rollup_commitment.message_result) ~rejected
    ~max_proof_size =
  let agreed = agreed.context_hash in
  Context.verify_stream_proof proof (fun tree ->
      let before = Context.Tree.hash tree in
      assert (Context_hash.(before = agreed)) ;
      (Verifier_apply.apply_message tree message >>= function
       | Ok (tree, message_result) -> Lwt.return (tree, Some message_result)
       | Error _ -> Lwt.return (tree, None))
      >>= fun (tree, message_result) ->
      let after = Context.Tree.hash tree in
      Lwt.return (tree, (after, message_result)))
  >>= fun verified ->
  match verified with
  | Ok (_, (after, message_result)) ->
      let withdraw =
        match message_result with
        | Some (_message_result, withdrawals) ->
            Alpha_context.Tx_rollup_withdraw.merkelize_list withdrawals
        | None -> Alpha_context.Tx_rollup_withdraw.merkelize_list []
      in
      let result_hash =
        Alpha_context.Tx_rollup_commitment.hash_message_result
          {context_hash = after; withdrawals_merkle_root = withdraw}
      in
      Lwt.return
        (not
           Alpha_context.Tx_rollup_message_result_hash.(
             equal rejected result_hash))
  | Error (`Stream_too_short _) ->
      let proof_size =
        Data_encoding.Binary.length Tx_rollup_l2_proof.encoding proof
      in
      Lwt.return Compare.Int.(proof_size > max_proof_size)
  | Error _ ->
      (* TODO/TORU: need to grovel thru error and check for too-large proof*)
      Lwt.return false
