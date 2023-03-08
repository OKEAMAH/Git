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

type coordinator = Coordinator

type committee_member = Committee_member

type observer = Observer

(* TODO: https://gitlab.com/tezos/tezos/-/issues/4707.
   Remove legacy mode once other DAC operating modes are fully functional. *)
type legacy = Legacy

module type Modal_type = sig
  type coordinator_t

  type committee_member_t

  type observer_t

  type legacy_t

  type 'a mode =
    | Coordinator : coordinator_t -> coordinator mode
    | Committee_member : committee_member_t -> committee_member mode
    | Observer : observer_t -> observer mode
    | Legacy : legacy_t -> legacy mode

  type t = Ex : 'a mode -> t
end

module Make_modal_type (T : sig
  type coordinator_t

  type committee_member_t

  type observer_t

  type legacy_t
end) :
  Modal_type
    with type coordinator_t = T.coordinator_t
     and type committee_member_t = T.committee_member_t
     and type observer_t = T.observer_t
     and type legacy_t = T.legacy_t
