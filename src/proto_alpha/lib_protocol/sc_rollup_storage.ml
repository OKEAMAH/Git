(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2021 Nomadic Labs <contact@nomadic-labs.com>                *)
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

let originate ctxt ~pvm_kind ~boot_sector =
  Raw_context.increment_origination_nonce ctxt >>?= fun (ctxt, nonce) ->
  Sc_rollup_repr.Address.from_nonce nonce >>=? fun address ->
  Storage.Sc_rollup.PVM_kind.add ctxt address pvm_kind >>= fun ctxt ->
  Storage.Sc_rollup.Boot_sector.add ctxt address boot_sector >>= fun ctxt ->
  Storage.Sc_rollup.Inbox.init ctxt address Sc_rollup_inbox.empty
  >>=? fun (ctxt, size_diff) ->
  let stored_kind_size = 2 (* because tag_size of kind encoding is 16bits. *) in
  let size =
    Z.of_int (stored_kind_size + Bytes.length boot_sector + size_diff)
  in
  return (ctxt, address, size)

let kind ctxt address = Storage.Sc_rollup.PVM_kind.find ctxt address

let add_messages ctxt rollup messages =
  Storage.Sc_rollup.Inbox.get ctxt rollup >>=? fun (ctxt, inbox) ->
  let inbox = Sc_rollup_inbox.add_messages inbox messages in
  Storage.Sc_rollup.Inbox.update ctxt rollup inbox >>=? fun (ctxt, size) ->
  return (ctxt, inbox, size)

let inbox ctxt rollup = Storage.Sc_rollup.Inbox.get ctxt rollup
