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

(** Tezos - BLS12-381 cryptography *)

include
  S.AGGREGATE_SIGNATURE
    with type Public_key.t = Bls12_381.Signature.MinPk.pk
     and type Secret_key.t = Bls12_381.Signature.sk
     and type t = Bls12_381.Signature.MinPk.signature
     and type watermark = Bytes.t

include S.RAW_DATA with type t := t

(** Same as {!sign} but without hashing the message with Blake2B. *)
val sign_raw : ?watermark:watermark -> Secret_key.t -> Bytes.t -> t

(** Same as {!check} but without hashing the message with Blake2B. *)
val check_raw : ?watermark:watermark -> Public_key.t -> t -> Bytes.t -> bool

(** Same as {!aggregate_check} but without hashing the message with Blake2B. *)
val aggregate_check_raw :
  (Public_key.t * watermark option * bytes) list -> t -> bool
