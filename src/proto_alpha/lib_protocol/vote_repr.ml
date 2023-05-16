(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2018 Dynamic Ledger Solutions, Inc. <contact@tezos.com>     *)
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

type proposal = Protocol_hash.t

type ballot = Yea | Nay | Pass

let ballot_legacy_encoding =
  let of_int8 = function
    | 0 -> Ok Yea
    | 1 -> Ok Nay
    | 2 -> Ok Pass
    | _ -> Error "ballot_of_int8"
  in
  let to_int8 = function Yea -> 0 | Nay -> 1 | Pass -> 2 in
  let open Data_encoding in
  (* union *)
  splitted
    ~binary:(conv_with_guard to_int8 of_int8 int8)
    ~json:(string_enum [("yay", Yea); ("nay", Nay); ("pass", Pass)])

let ballot_encoding =
  let of_int8 = function
    | 0 -> Ok Yea
    | 1 -> Ok Nay
    | 2 -> Ok Pass
    | _ -> Error "ballot_of_int8"
  in
  let to_int8 = function Yea -> 0 | Nay -> 1 | Pass -> 2 in
  let open Data_encoding in
  (* union *)
  splitted
    ~binary:(conv_with_guard to_int8 of_int8 int8)
    ~json:(string_enum [("yea", Yea); ("nay", Nay); ("pass", Pass)])

let equal_ballot a b =
  match (a, b) with Yea, Yea | Nay, Nay | Pass, Pass -> true | _ -> false

let pp_ballot ppf = function
  | Yea -> Format.fprintf ppf "yea"
  | Nay -> Format.fprintf ppf "nay"
  | Pass -> Format.fprintf ppf "pass"
