(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2023 Trili Tech, <contact@trili.tech>                       *)
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

(* TODO: https://gitlab.com/tezos/tezos/-/issues/5019
   Should we use Gadts and get rid of variant types? *)
(* A variant type that defines different values according to the operating
   mode. *)
type ('coordinator, 'committee_member, 'observer, 'legacy) t =
  | Coordinator of 'coordinator
  | Committee_member of 'committee_member
  | Observer of 'observer
  | Legacy of 'legacy

(* [make_encoding ~coordinator_encoding ~committee_member_encoding
    ~observer_encoding ~legacy_encoding] constructs a union encoding
    from the encodings given for each operating mode. *)
val make_encoding :
  coordinator_encoding:'coordinator Data_encoding.t ->
  committee_member_encoding:'committee_member Data_encoding.t ->
  observer_encoding:'observer Data_encoding.t ->
  legacy_encoding:'legacy Data_encoding.t ->
  ('coordinator, 'committee_member, 'observer, 'legacy) t Data_encoding.t
