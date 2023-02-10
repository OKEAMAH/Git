(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2022 Marigold <contact@marigold.dev>                        *)
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
open Tezos_scoru_wasm_fast
module P = Pool.Make (Pool.LeastRecentlyUsed)

let int_range a b = Stdlib.List.init (b - a) (fun x -> a + x)

let ints_to_str lst =
  let s = String.concat "," @@ List.map Int.to_string lst in
  "[" ^ s ^ "]"

let ints_sort = List.sort Int.compare

let test_concurrent_access _switch () =
  let collisions = 100 in
  let slots = 3 in
  let pool = P.init slots in
  let computation n =
    let k = n mod slots in
    let key = "key_" ^ Int.to_string k in
    Printf.printf "key=%s, n=%d\n" key n ;
    let ctor () = n in
    pool |> P.use key ctor @@ fun v -> Lwt.return v
  in
  let open Lwt.Syntax in
  let* results =
    int_range 0 (slots * collisions) |> List.map computation |> Lwt.all
  in

  Printf.printf "lst=%s\n\n" @@ ints_to_str results ;
  let sorted_results = ints_sort results in
  let expected_results =
    ints_sort @@ List.concat_map (List.repeat collisions) @@ int_range 0 slots
  in
  Printf.printf "expected=%s\n\n" @@ ints_to_str results ;
  assert (sorted_results = expected_results) ;
  Lwt.return ()

let tests : unit Alcotest_lwt.test_case list =
  [
    Alcotest_lwt.test_case
      "test concurrent access to the same element"
      `Quick
      test_concurrent_access;
  ]
