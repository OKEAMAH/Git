(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2023 TriliTech, <contact@trili.tech>                        *)
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

(* TODO: https://gitlab.com/tezos/tezos/-/issues/5073
   Update Certificate repr to handle a dynamic dac.
*)

(* Representation of a Data Availibility Committee Certificate. *)
type t = {
  root_hash : Dac_plugin.hash;
  aggregate_signature : Tezos_crypto.Aggregate_signature.signature;
  witnesses : Z.t;
      (* TODO: https://gitlab.com/tezos/tezos/-/issues/4853
         Use BitSet for witnesses field in external message
      *)
}

let encoding ((module P) : Dac_plugin.t) =
  let obj_enc =
    Data_encoding.(
      obj3
        (req "root_hash" P.encoding)
        (req "aggregate_signature" Tezos_crypto.Aggregate_signature.encoding)
        (req "witnesses" z))
  in

  Data_encoding.(
    conv
      (fun {root_hash; aggregate_signature; witnesses} ->
        (root_hash, aggregate_signature, witnesses))
      (fun (root_hash, aggregate_signature, witnesses) ->
        {root_hash; aggregate_signature; witnesses})
      obj_enc)
