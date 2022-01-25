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

type t = {
  first_unfinalized_level : Raw_level_repr.t option;
  unfinalized_level_count : int;
  fees_per_byte : Tez_repr.t;
  last_inbox_level : Raw_level_repr.t option;
}

let initial_state =
  {
    first_unfinalized_level = None;
    unfinalized_level_count = 0;
    fees_per_byte = Tez_repr.zero;
    last_inbox_level = None;
  }

let encoding : t Data_encoding.t =
  let open Data_encoding in
  conv
    (fun {
           first_unfinalized_level;
           unfinalized_level_count;
           fees_per_byte;
           last_inbox_level;
         } ->
      ( first_unfinalized_level,
        unfinalized_level_count,
        fees_per_byte,
        last_inbox_level ))
    (fun ( first_unfinalized_level,
           unfinalized_level_count,
           fees_per_byte,
           last_inbox_level ) ->
      {
        first_unfinalized_level;
        unfinalized_level_count;
        fees_per_byte;
        last_inbox_level;
      })
    (obj4
       (req "first_unfinalized_level" (option Raw_level_repr.encoding))
       (req "unfinalized_level_count" int16)
       (req "fees_per_byte" Tez_repr.encoding)
       (req "last_inbox_level" (option Raw_level_repr.encoding)))

let pp fmt
    {
      first_unfinalized_level;
      unfinalized_level_count;
      fees_per_byte;
      last_inbox_level;
    } =
  Format.fprintf
    fmt
    "first_unfinalized_level %a unfinalized_level_count %d cost_per_byte: %a \
     newest inbox %a"
    (Format.pp_print_option Raw_level_repr.pp)
    first_unfinalized_level
    unfinalized_level_count
    Tez_repr.pp
    fees_per_byte
    (Format.pp_print_option Raw_level_repr.pp)
    last_inbox_level

(* TODO: https://gitlab.com/tezos/tezos/-/issues/2338
   To get a smoother variation of fees, that is more resistant to
   spurious pikes of data, we will use EMA.

   The type [t] probably needs to be updated accordingly. *)
let update_fees_per_byte : t -> final_size:int -> hard_limit:int -> t =
 fun ({fees_per_byte; _} as state) ~final_size ~hard_limit ->
  let threshold_increase = 90 in
  let threshold_decrease = 80 in
  let variation_factor = 5L in
  let computation =
    let open Compare.Int in
    let percentage = final_size * 100 / hard_limit in
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
  | Ok fees_per_byte -> {state with fees_per_byte}
  (* In the (very unlikely) event of an overflow, we force the fees to
     be the maximum amount. *)
  | Error _ -> {state with fees_per_byte = Tez_repr.max_mutez}

let fees {fees_per_byte; _} size = Tez_repr.(fees_per_byte *? Int64.of_int size)

let last_inbox_level {last_inbox_level; _} = last_inbox_level

let append_inbox t level =
  {
    t with
    last_inbox_level = Some level;
    first_unfinalized_level =
      Some (Option.value ~default:level t.first_unfinalized_level);
  }

let unfinalized_level_count {unfinalized_level_count; _} =
  unfinalized_level_count

let first_unfinalized_level {first_unfinalized_level; _} =
  first_unfinalized_level

let increment_unfinalized_level_count state =
  {state with unfinalized_level_count = state.unfinalized_level_count + 1}

let update_after_finalize state level count =
  {
    state with
    first_unfinalized_level = level;
    unfinalized_level_count = state.unfinalized_level_count - count;
  }

module Internal_for_tests = struct
  let initial_state_with_fees_per_byte : Tez_repr.t -> t =
   fun fees_per_byte ->
    {
      first_unfinalized_level = None;
      unfinalized_level_count = 0;
      fees_per_byte;
      last_inbox_level = None;
    }
end

include Compare.Make (struct
  type nonrec t = t

  let compare
      {
        first_unfinalized_level = first_unfinalized_level1;
        unfinalized_level_count = unfinalized_level_count1;
        fees_per_byte = fees_per_byte1;
        last_inbox_level = last_inbox_level1;
      }
      {
        first_unfinalized_level = first_unfinalized_level2;
        unfinalized_level_count = unfinalized_level_count2;
        fees_per_byte = fees_per_byte2;
        last_inbox_level = last_inbox_level2;
      } =
    match Tez_repr.compare fees_per_byte1 fees_per_byte2 with
    | 0 -> (
        match
          Option.compare
            Raw_level_repr.compare
            first_unfinalized_level1
            first_unfinalized_level2
        with
        | 0 -> (
            match
              Compare.Int.compare
                unfinalized_level_count1
                unfinalized_level_count2
            with
            | 0 ->
                Option.compare
                  Raw_level_repr.compare
                  last_inbox_level1
                  last_inbox_level2
            | c -> c)
        | c -> c)
    | c -> c
end)
