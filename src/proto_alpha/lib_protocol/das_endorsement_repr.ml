(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2022 Nomadic Labs <contact@nomadic-labs.com>                *)
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

(* DAS/FIXME: This may be a bit heavy in practice. We could also
   assume that in practice, this bitfield will contain many bits to
   one. Hence, we could consider a better encoding which is smaller in
   the optimistic case. For example:

   1. When all the slot is endorsed, the encoding can be represented
   in one octet.

   2. Otherwise, we can pack slots by [8]. Have a header of [slots/8]
   which is [1] if all the slots in this set are [1], [0]
   otherwise. For all pack with a bit set to [0], we give the explicit
   representation. Hence, if there are [256] slots, and [2] are not
   endorsed, this representation will be of size [32] bits + [16] bits =
   [48] bits which is better than [256]. *)
type t = Bitset.t

let encoding = Bitset.encoding

let empty = Bitset.empty

let mem t index =
  match Bitset.mem t index with
  | Ok b -> b
  | Error _ -> (* DAS/FIXME Should we do something here? *) false

let add t index =
  match Bitset.add t index with
  | Ok t -> t
  | Error _ -> (* DAS/FIXME Should we do something here? *) t

let expected_size ~max_index =
  (* We compute an encoding of the data-availability endorsements
     which is a (tight) upper bound of what we expect. *)
  let open Bitset in
  match add empty (max_index - 1) with
  | Error _ -> (* Happens if max_index < 1 *) 0
  | Ok t -> size t

let size = Bitset.size
