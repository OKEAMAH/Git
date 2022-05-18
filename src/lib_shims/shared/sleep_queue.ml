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

module Key = struct
  type t = { resolver : unit Lwt.u; key : int }

  let compare x y = Int.compare x.key y.key

  let assign_id =
    let x = ref 0 in
    fun resolver ->
      let key = !x in
      incr x ;
      { resolver; key }
end

module Prio = Float
module Prioqueue = Psq.Make (Key) (Prio)

module Create () = struct
  type t = { mutable now : float; mutable queue : Prioqueue.t }

  let now = ref (Unix.gettimeofday ())

  let queue = ref Prioqueue.empty

  let rec scheduler queue =
    match Prioqueue.pop queue with
    | None -> queue
    | Some ((key, wakeup_time), rest) ->
        if wakeup_time <= !now then (
          Lwt.wakeup_later key.resolver () ;
          scheduler rest )
        else queue

  let elapse seconds =
    assert (seconds > 0.) ;
    now := !now +. seconds ;
    let current_queue = !queue in
    queue := Prioqueue.empty ;
    let remaining = scheduler current_queue in
    (* Invariant: all elements added during scheduling are in the future
       and do not need to be scheduled now. *)
    queue := Prioqueue.(remaining ++ !queue)

  let sleep seconds =
    let (promise, resolver) = Lwt.task () in
    let wakeup_at = !now +. seconds in
    queue := Prioqueue.add (Key.assign_id resolver) wakeup_at !queue ;
    promise

  let now () = !now

  let next_wakeup () =
    Option.map snd (Prioqueue.min !queue)
end
