(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2022 Nomadic Labs <contact@nomadic-labs.com>                *)
(* Copyright (c) 2022 Trili Tech, <contact@trili.tech>                       *)
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

open Sc_rollup_repr

module Hash = struct
  include Smart_rollup.Commitment_hash
  include Path_encoding.Make_hex (Smart_rollup.Commitment_hash)
end

module V1 = struct
  type compressed = State of State_hash.t | Diff of Diff_hash.t

  let get_state = function State s -> s | _ -> assert false

  type t = {
    compressed_state : compressed;
    inbox_level : Raw_level_repr.t;
    predecessor : Hash.t;
    number_of_ticks : Number_of_ticks.t;
  }

  let pp_compressed fmt c =
    match c with
    | State h -> Format.fprintf fmt "state %a@" State_hash.pp h
    | Diff h -> Format.fprintf fmt "diff %a@" Diff_hash.pp h

  let compressed_encoding =
    let open Data_encoding in
    let state_tag = 0 and state_encoding = State_hash.encoding in
    let diff_tag = 1 and diff_encoding = Diff_hash.encoding in
    let state_size =
      Stdlib.Option.get @@ Data_encoding.Binary.fixed_length state_encoding
    in
    let diff_size =
      Stdlib.Option.get @@ Data_encoding.Binary.fixed_length diff_encoding
    in
    let max_size = max state_size diff_size in

    let state_encoding =
      let padding = max_size - state_size in
      if padding > 0 then Data_encoding.Fixed.add_padding state_encoding padding
      else state_encoding
    in
    let diff_encoding =
      let padding = max_size - diff_size in
      if padding > 0 then Data_encoding.Fixed.add_padding diff_encoding padding
      else diff_encoding
    in
    let s1 = Data_encoding.Binary.fixed_length state_encoding in
    let s2 = Data_encoding.Binary.fixed_length diff_encoding in
    assert (0 = Option.compare Int.compare s1 s2) ;
    matching
      ~tag_size:`Uint8
      (function
        | State s -> matched state_tag state_encoding s
        | Diff d -> matched diff_tag diff_encoding d)
      [
        case
          ~title:"State"
          (Tag state_tag)
          state_encoding
          (function State s -> Some s | _ -> None)
          (fun s -> State s);
        case
          ~title:"Diff"
          (Tag diff_tag)
          diff_encoding
          (function Diff d -> Some d | _ -> None)
          (fun d -> Diff d);
      ]

  let pp fmt {compressed_state; inbox_level; predecessor; number_of_ticks} =
    Format.fprintf
      fmt
      "compressed_state: %a@,\
       inbox_level: %a@,\
       predecessor: %a@,\
       number_of_ticks: %Ld"
      pp_compressed
      compressed_state
      Raw_level_repr.pp
      inbox_level
      Hash.pp
      predecessor
      (Number_of_ticks.to_value number_of_ticks)

  let encoding =
    let open Data_encoding in
    conv
      (fun {compressed_state; inbox_level; predecessor; number_of_ticks} ->
        (compressed_state, inbox_level, predecessor, number_of_ticks))
      (fun (compressed_state, inbox_level, predecessor, number_of_ticks) ->
        {compressed_state; inbox_level; predecessor; number_of_ticks})
      (obj4
         (req "compressed_state" compressed_encoding)
         (req "inbox_level" Raw_level_repr.encoding)
         (req "predecessor" Hash.encoding)
         (req "number_of_ticks" Number_of_ticks.encoding))

  let hash_uncarbonated commitment =
    let commitment_bytes =
      Data_encoding.Binary.to_bytes_exn encoding commitment
    in
    Hash.hash_bytes [commitment_bytes]

  (* For [number_of_messages] and [number_of_ticks] min_value is equal to zero. *)
  let genesis_commitment ~origination_level ~genesis_state_hash =
    let open Sc_rollup_repr in
    let number_of_ticks = Number_of_ticks.zero in
    {
      compressed_state = State genesis_state_hash;
      inbox_level = origination_level;
      predecessor = Hash.zero;
      number_of_ticks;
    }

  type genesis_info = {level : Raw_level_repr.t; commitment_hash : Hash.t}

  let genesis_info_encoding =
    let open Data_encoding in
    conv
      (fun {level; commitment_hash} -> (level, commitment_hash))
      (fun (level, commitment_hash) -> {level; commitment_hash})
      (obj2
         (req "level" Raw_level_repr.encoding)
         (req "commitment_hash" Hash.encoding))
end

type versioned = V1 of V1.t

let versioned_encoding =
  let open Data_encoding in
  union
    [
      case
        ~title:"V1"
        (Tag 0)
        V1.encoding
        (function V1 commitment -> Some commitment)
        (fun commitment -> V1 commitment);
    ]

include V1

let of_versioned = function V1 commitment -> commitment [@@inline]

let to_versioned commitment = V1 commitment [@@inline]
