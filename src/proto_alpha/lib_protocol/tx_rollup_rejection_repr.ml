(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2022 Marigold <contact@marigold.dev>                        *)
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

type error += (* `Permanent *) Wrong_rejection

let () =
  let open Data_encoding in
  (* Wrong_rejection *)
  register_error_kind
    `Temporary
    ~id:"Wrong_rejection"
    ~title:"This rejection wrongly attempts to reject a correct comitment"
    ~description:"This rejection wrongly attempts to reject a correct comitment"
    unit
    (function Wrong_rejection -> Some () | _ -> None)
    (fun () -> Wrong_rejection)

type t = {
  rollup : Tx_rollup_repr.t;
  level : Raw_level_repr.t;
  hash : Tx_rollup_commitments_repr.Commitment_hash.t;
  batch_index : int;
}

let encoding =
  let open Data_encoding in
  conv
    (fun {rollup; level; hash; batch_index} ->
      (rollup, level, hash, batch_index))
    (fun (rollup, level, hash, batch_index) ->
      {rollup; level; hash; batch_index})
    (obj4
       (req "rollup" Tx_rollup_repr.encoding)
       (req "level" Raw_level_repr.encoding)
       (req "hash" Tx_rollup_commitments_repr.Commitment_hash.encoding)
       (req "batch_index" int31))
