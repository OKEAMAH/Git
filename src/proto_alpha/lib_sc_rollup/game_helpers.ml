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

open Protocol.Alpha_context.Sc_rollup

(* Auxiliary function
   [exact_dissection ~rem ~dilate t1 number_of_pieces min_piece_size]
   creates a roughly equidistant dissection starting at [t1] with
   [number_of_pieces]  each of size at least [min_piece_size].
   It satisfies the following invariants:
   1. each piece has size a multiple of dilate
   2. the size difference between two pieces is either 0 or dilate
   3. the first rem pieces have size [(min_piece_size + 1) * dilate]
   4. the last pieces have size [min_piece_size * dilate]
*)
let exact_dissection ?rem ?(dilate = Z.one) t1 number_of_pieces min_piece_size =
  let f i =
    let j = Z.of_int @@ succ i in
    match rem with
    | Some r when j < r ->
        Tick.jump t1 @@ Z.((Z.one + min_piece_size) * j * dilate)
    | Some r -> Tick.jump t1 @@ Z.(((min_piece_size * j) + r) * dilate)
    | None -> Tick.jump t1 @@ Z.(min_piece_size * j * dilate)
  in
  Stdlib.List.init (number_of_pieces - 1) f

(* This version of default new section eliminates the large section at the
   end, the difference in size between two sections is at most 1. *)
let default_new_dissection ~default_number_of_sections
    ~(start_chunk : Game.dissection_chunk)
    ~(our_stop_chunk : Game.dissection_chunk) =
  let max_number_of_sections = Z.of_int default_number_of_sections in
  let trace_length = Tick.distance our_stop_chunk.tick start_chunk.tick in
  if trace_length <= max_number_of_sections then
    (* In this case, every section is of length one. *)
    exact_dissection start_chunk.tick (Z.to_int trace_length) Z.one
  else
    let div, rem = Z.(div_rem trace_length max_number_of_sections) in
    if rem = Z.zero then
      exact_dissection start_chunk.tick default_number_of_sections div
    else exact_dissection ~rem start_chunk.tick default_number_of_sections div

let make_dissection ~state_hash_from_tick ~start_chunk ~our_stop_chunk ticks =
  let rec make_dissection_aux ticks acc =
    let open Lwt_result_syntax in
    match ticks with
    | tick :: rst ->
        let* state_hash = state_hash_from_tick tick in
        let chunk = Dissection_chunk.{tick; state_hash} in
        make_dissection_aux rst (chunk :: acc)
    | [] -> return @@ List.rev (our_stop_chunk :: acc)
  in
  make_dissection_aux ticks [start_chunk]

module Wasm = struct
  let new_dissection ?(ticks_per_snapshot = Wasm_2_0_0PVM.ticks_per_snapshot)
      ~default_number_of_sections start_chunk our_stop_chunk =
    let open Dissection_chunk in
    let dist = Tick.distance start_chunk.tick our_stop_chunk.tick in
    (*
         If the distance between the start and stop chunk is lesser than a 
         snapshot, we have already found the kernel_run invocation we
         were looking for and so we use the default.
      *)
    if Compare.Z.(dist <= ticks_per_snapshot) then
      default_new_dissection
        ~default_number_of_sections
        ~start_chunk
        ~our_stop_chunk
    else
      let tick_as_z = Tick.to_z start_chunk.tick in
      let reminder = Z.rem tick_as_z ticks_per_snapshot in
      (* we first find the first snapshot following [start_chunk.tick] *)
      let is_stop_chunk_aligned = Compare.Z.(reminder = Z.zero) in
      let initial_tick =
        if is_stop_chunk_aligned then start_chunk.tick
        else Tick.of_z Z.(tick_as_z + ticks_per_snapshot - reminder)
      in
      let dist = Tick.distance initial_tick our_stop_chunk.tick in
      let max_number_of_sections, reminder =
        Z.(div_rem dist ticks_per_snapshot)
      in
      let number_of_sections =
        Z.min
          (Z.of_int
             (default_number_of_sections
             - if is_stop_chunk_aligned then 0 else 1))
          Z.(
            max_number_of_sections + if reminder = Z.zero then Z.zero else Z.one)
      in
      (* We now create a dissection with number_of_sections each
         (aside from possibly first and last) of size
         [min_piece_size * ticks_per_snapshot] or
          [(min_piece_size + 1) * ticks_per_snapshot]
          The section ticks will all be aligned.
          Note that if  default_number_of_sections >default_number_of_sections
            then min_piece_size = 1*)
      let min_piece_size, rem =
        Z.div_rem max_number_of_sections number_of_sections
      in
      let l =
        exact_dissection
          ~rem
          ~dilate:ticks_per_snapshot
          initial_tick
          (Z.to_int number_of_sections)
          min_piece_size
      in
      if is_stop_chunk_aligned then l else initial_tick :: l
end
