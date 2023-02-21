(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) Nomadic Labs, <contact@nomadic-labs.com>.                   *)
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

(** Testing
    -------
    Component:    Smart rollup helpers
    Invocation:   dune exec src/proto_alpha/lib_sc_rollup/test/main.exe -- \
                  -f dissection
    Subject:      Dissection
 *)

open Protocol.Alpha_context.Sc_rollup
open Game_helpers

let tick_to_int_exn ?(__LOC__ = __LOC__) t =
  WithExceptions.Option.get ~loc:__LOC__ (Tick.to_int t)

let tick_of_int_exn ?(__LOC__ = __LOC__) n =
  WithExceptions.Option.get ~loc:__LOC__ (Tick.of_int n)

let gen_number_sections =
  QCheck2.Gen.int_range
    ~origin:32
    4
    (* FIXME: Under 3 sections, (any) dissection generates incorrect dissections
       (Maximum tick increment in a section cannot be more than ... ticks). *)
    255

let gen_tick_int ?(min = 0) () =
  let open QCheck2.Gen in
  min -- max_int

let gen_tick ?min () =
  let open QCheck2.Gen in
  let+ i = gen_tick_int ?min () in
  tick_of_int_exn i

let state_hash_of_tick tick =
  let s = Tick.to_z tick |> Z.to_bits in
  let len = String.length s in
  let s =
    Bytes.init State_hash.size (fun i -> if i >= len then '\000' else s.[i])
  in
  State_hash.of_bytes_exn s

let gen_chunk ?(none = false) ?tick ?min_tick () =
  let open QCheck2.Gen in
  let+ tick =
    match tick with
    | None -> gen_tick ?min:min_tick ()
    | Some t -> pure (tick_of_int_exn t)
  in
  let state_hash = if none then None else Some (state_hash_of_tick tick) in
  Dissection_chunk.{state_hash; tick}

let gen_start_stop_chunks ?ticks_per_snapshot ?(initial = false)
    ?(min_number_of_ticks = 2) () =
  let open QCheck2.Gen in
  let* start_tick =
    let+ i = small_nat in
    Option.map (( * ) i) ticks_per_snapshot
    (* Start tick needs to be aligned for WASM dissection to work
       correctly. Otherwise generates incorrect dissections (The number of
       sections must be equal to 32 instead of 2). *)
  in
  let* start_chunk = gen_chunk ?tick:start_tick () in
  let min_stop_tick = tick_to_int_exn start_chunk.tick + min_number_of_ticks in
  let+ stop_chunk = gen_chunk ~none:initial ~min_tick:min_stop_tick () in
  (start_chunk, stop_chunk)

let gen_make_dissection ?min_number_of_ticks ?ticks_per_snapshot new_dissection
    =
  let open QCheck2.Gen in
  let* default_number_of_sections = gen_number_sections in
  let* initial =
    let+ p = float_range 0. 1. in
    p <= 0.05
  in
  let+ start_chunk, our_stop_chunk =
    gen_start_stop_chunks ?ticks_per_snapshot ~initial ?min_number_of_ticks ()
  in
  let state_hash_from_tick tick =
    Lwt.return_ok @@ Some (state_hash_of_tick tick)
  in
  let res =
    Lwt_main.run
    @@ make_dissection ~state_hash_from_tick ~start_chunk ~our_stop_chunk
    @@ new_dissection ~default_number_of_sections ~start_chunk ~our_stop_chunk
  in
  (default_number_of_sections, start_chunk, our_stop_chunk, res)

let test_make_dissection ~name ?ticks_per_snapshot ?min_number_of_ticks
    new_dissection check_dissection =
  let print (default_number_of_sections, start_chunk, stop_chunk, res) =
    let pp_res ppf = function
      | Error _ -> Format.pp_print_string ppf "Error"
      | Ok d -> Game.pp_dissection ppf d
    in
    Format.asprintf
      "@[<v>@[default_number_of_sections:@ %d@]@,\
       @[start:@ {%a}@]@,\
       @[stop:@ {%a}@]@,\
       @[dissection:@ [%a]@]@]"
      default_number_of_sections
      Dissection_chunk.pp
      start_chunk
      Dissection_chunk.pp
      stop_chunk
      pp_res
      res
  in
  let check_dissection (default_number_of_sections, start_chunk, stop_chunk, res)
      =
    let open Result_syntax in
    let res =
      let* dissection = res in
      Environment.wrap_tzresult
      @@ check_dissection
           ~default_number_of_sections
           ~start_chunk
           ~stop_chunk:
             Dissection_chunk.
               {stop_chunk with state_hash = Some State_hash.zero}
           (* We have to use a different state for the stop chunk because
              [check_dissection] also ensures that the dissection correctly
              identifies the disagreement state. *)
           dissection
    in
    match res with
    | Error err ->
        QCheck2.Test.fail_reportf "%a@." Error_monad.pp_print_trace err
    | Ok () -> true
  in
  let ticks_per_snapshot = Option.map Z.to_int ticks_per_snapshot in
  let test =
    QCheck2.Test.make
      ~name
      ~count:100_000
      ~print
      (gen_make_dissection
         ?min_number_of_ticks
         ?ticks_per_snapshot
         new_dissection)
      check_dissection
  in
  (String.concat ": " [Protocol.name; name], Qcheck2_helpers.qcheck_wrap [test])

let tests =
  [
    test_make_dissection
      ~name:"make_dissection_default"
      default_new_dissection
      ArithPVM.Protocol_implementation.check_dissection;
    test_make_dissection
      ~name:"make_dissection_wasm_big"
      ~min_number_of_ticks:55_000_000_000
      ~ticks_per_snapshot:Wasm_2_0_0PVM.ticks_per_snapshot
      Wasm.new_dissection
      Wasm_2_0_0PVM.Protocol_implementation.check_dissection;
    test_make_dissection
      ~name:"make_dissection_wasm_small"
      ~ticks_per_snapshot:Wasm_2_0_0PVM.ticks_per_snapshot
      Wasm.new_dissection
      Wasm_2_0_0PVM.Protocol_implementation.check_dissection;
  ]

let () = Alcotest.run "dissection" tests
