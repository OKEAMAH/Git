(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2022 Marigold <contact@marigold.dev>                        *)
(* Copyright (c) 2022 Nomadic Labs <contact@nomadic-labs.com>                *)
(* Copyright (c) 2022 Oxhead Alpha <info@oxhead-alpha.com>                   *)
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

(** The state of a transaction rollup is composed of [fees_per_byte]
    and [inbox_ema] fields. [initial_state] introduces their initial
    values. Both values are updated by [update_fees_per_byte] as the
    rollup progresses.

    [fees_per_byte] state the cost of fees per byte to be paid for
    each byte submitted to a transaction rollup inbox. [inbox_ema]
    is a key factor to impact the update of [fees_per_byte].

    [inbox_ema] is the N-block EMA to react to recent N-inbox size
    changes. N-block EMA is an exponential moving average (EMA), that
    is a type of moving average that places a greater weight and
    significance on the most N data points. The purpose of [inbox_ema]
    is to get lessened volatility of fees, that is more resistant to
    spurious spikes of [fees_per_byte].
*)
type t = {
  first_unfinalized_level : Raw_level_repr.t option;
  unfinalized_level_count : int;
  fees_per_byte : Tez_repr.t;
  inbox_ema : int;
  last_inbox_level : Raw_level_repr.t option;
}

let initial_state =
  {
    first_unfinalized_level = None;
    unfinalized_level_count = 0;
    fees_per_byte = Tez_repr.zero;
    inbox_ema = 0;
    last_inbox_level = None;
  }

let encoding : t Data_encoding.t =
  let open Data_encoding in
  conv
    (fun {
           first_unfinalized_level;
           unfinalized_level_count;
           fees_per_byte;
           inbox_ema;
           last_inbox_level;
         } ->
      ( first_unfinalized_level,
        unfinalized_level_count,
        fees_per_byte,
        inbox_ema,
        last_inbox_level ))
    (fun ( first_unfinalized_level,
           unfinalized_level_count,
           fees_per_byte,
           inbox_ema,
           last_inbox_level ) ->
      {
        first_unfinalized_level;
        unfinalized_level_count;
        fees_per_byte;
        inbox_ema;
        last_inbox_level;
      })
    (obj5
       (req "first_unfinalized_level" (option Raw_level_repr.encoding))
       (req "unfinalized_level_count" int16)
       (req "fees_per_byte" Tez_repr.encoding)
       (req "inbox_ema" int31)
       (req "last_inbox_level" (option Raw_level_repr.encoding)))

let pp fmt
    {
      first_unfinalized_level;
      unfinalized_level_count;
      fees_per_byte;
      inbox_ema;
      last_inbox_level;
    } =
  Format.fprintf
    fmt
    "first_unfinalized_level: %a unfinalized_level_count: %d cost_per_byte: %a \
     inbox_ema: %d newest inbox: %a"
    (Format.pp_print_option Raw_level_repr.pp)
    first_unfinalized_level
    unfinalized_level_count
    Tez_repr.pp
    fees_per_byte
    inbox_ema
    (Format.pp_print_option Raw_level_repr.pp)
    last_inbox_level

let update_fees_per_byte : t -> final_size:int -> hard_limit:int -> t =
 fun ({fees_per_byte; inbox_ema; _} as state) ~final_size ~hard_limit ->
  let threshold_increase = 90 in
  let threshold_decrease = 80 in
  let variation_factor = 5L in
  (* The formula of the multiplier of EMA :

       smoothing / (1 + N)

     Suppose the period we want to observe is an hour and
     producing a block takes 30 seconds, then, N is equal
     to 120. The common choice of smoothing is 2. Therefore,
     multiplier of EMA:

       2 / (1 + 120) ~= 0.0165 *)
  let inbox_ema_multiplier = 165 in
  let inbox_ema =
    ((final_size * inbox_ema_multiplier)
    + (inbox_ema * (10000 - inbox_ema_multiplier)))
    / 10000
  in
  let percentage = inbox_ema * 100 / hard_limit in
  let computation =
    let open Compare.Int in
    if threshold_decrease < percentage && percentage <= threshold_increase then
      (* constant case *)
      ok fees_per_byte
    else
      Tez_repr.(fees_per_byte *? variation_factor >>? fun x -> x /? 100L)
      >>? fun variation ->
      let variation =
        if Tez_repr.(variation = zero) then Tez_repr.one_mutez else variation
      in
      (* increase case *)
      if threshold_increase < percentage then
        Tez_repr.(fees_per_byte +? variation)
      else if percentage < threshold_decrease && Tez_repr.(zero < fees_per_byte)
      then
        (* decrease case, and strictly positive fees *)
        Tez_repr.(fees_per_byte -? variation)
      else (* decrease case, and fees equals zero *)
        ok fees_per_byte
  in
  match computation with
  | Ok fees_per_byte -> {state with fees_per_byte; inbox_ema}
  (* In the (very unlikely) event of an overflow, we force the fees to
     be the maximum amount. *)
  | Error _ -> {state with fees_per_byte = Tez_repr.max_mutez; inbox_ema}

let fees {fees_per_byte; _} size = Tez_repr.(fees_per_byte *? Int64.of_int size)

let last_inbox_level {last_inbox_level; _} = last_inbox_level

let append_inbox t level =
  {
    t with
    last_inbox_level = Some level;
    first_unfinalized_level =
      Some (Option.value ~default:level t.first_unfinalized_level);
    unfinalized_level_count = t.unfinalized_level_count + 1;
  }

let unfinalized_level_count {unfinalized_level_count; _} =
  unfinalized_level_count

let first_unfinalized_level {first_unfinalized_level; _} =
  first_unfinalized_level

let update_after_finalize state level count =
  {
    state with
    first_unfinalized_level = level;
    unfinalized_level_count = state.unfinalized_level_count - count;
  }

module Internal_for_tests = struct
  let make :
      fees_per_byte:Tez_repr.t ->
      inbox_ema:int ->
      last_inbox_level:Raw_level_repr.t option ->
      t =
   fun ~fees_per_byte ~inbox_ema ~last_inbox_level ->
    {
      fees_per_byte;
      inbox_ema;
      last_inbox_level;
      first_unfinalized_level = None;
      unfinalized_level_count = 0;
    }

  let get_inbox_ema : t -> int = fun {inbox_ema; _} -> inbox_ema
end
