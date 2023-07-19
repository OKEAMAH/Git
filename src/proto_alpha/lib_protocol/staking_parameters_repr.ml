(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2023 Nomadic Labs <contact@nomadic-labs.com>                *)
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
  limit_of_staking_over_baking_millionth : int32;
  edge_of_baking_over_staking_billionth : int32;
}

let maximum_edge_of_baking_over_staking_billionth =
  (* max is 1 (1_000_000_000 billionth) *)
  1_000_000_000l

let default =
  {
    limit_of_staking_over_baking_millionth = 0l;
    edge_of_baking_over_staking_billionth = 1_000_000_000l;
  }

type error += Invalid_staking_parameters

let () =
  register_error_kind
    `Permanent
    ~id:"operations.invalid_staking_parameters"
    ~title:"Invalid parameters for staking parameters"
    ~description:"The staking parameters are invalid."
    ~pp:(fun ppf () -> Format.fprintf ppf "Invalid staking parameters")
    Data_encoding.empty
    (function Invalid_staking_parameters -> Some () | _ -> None)
    (fun () -> Invalid_staking_parameters)

let make ~limit_of_staking_over_baking_millionth
    ~edge_of_baking_over_staking_billionth =
  if
    Compare.Int32.(limit_of_staking_over_baking_millionth < 0l)
    || Compare.Int32.(edge_of_baking_over_staking_billionth < 0l)
    || Compare.Int32.(
         edge_of_baking_over_staking_billionth
         > maximum_edge_of_baking_over_staking_billionth)
  then Error ()
  else
    Ok
      {
        limit_of_staking_over_baking_millionth;
        edge_of_baking_over_staking_billionth;
      }

let encoding =
  let open Data_encoding in
  conv_with_guard
    (fun {
           limit_of_staking_over_baking_millionth;
           edge_of_baking_over_staking_billionth;
         } ->
      ( limit_of_staking_over_baking_millionth,
        edge_of_baking_over_staking_billionth ))
    (fun ( limit_of_staking_over_baking_millionth,
           edge_of_baking_over_staking_billionth ) ->
      Result.map_error
        (fun () -> "Invalid staking parameters")
        (make
           ~limit_of_staking_over_baking_millionth
           ~edge_of_baking_over_staking_billionth))
    (obj2
       (req "limit_of_staking_over_baking_millionth" int32)
       (req "edge_of_baking_over_staking_billionth" int32))

let make ~limit_of_staking_over_baking_millionth
    ~edge_of_baking_over_staking_billionth =
  let open Result_syntax in
  if
    Compare.Z.(limit_of_staking_over_baking_millionth < Z.zero)
    || Compare.Z.(edge_of_baking_over_staking_billionth < Z.zero)
  then tzfail Invalid_staking_parameters
  else
    let limit_of_staking_over_baking_millionth =
      match Z.to_int32 limit_of_staking_over_baking_millionth with
      | Ok i -> i
      | Error _ -> Int32.max_int
    in
    let* edge_of_baking_over_staking_billionth =
      Z.to_int32 edge_of_baking_over_staking_billionth
    in
    match
      make
        ~limit_of_staking_over_baking_millionth
        ~edge_of_baking_over_staking_billionth
    with
    | Error () -> tzfail Invalid_staking_parameters
    | Ok _ as ok -> ok
