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
  limit_of_staking_over_baking_millionth : Uint63.t;
  edge_of_baking_over_staking_billionth : Uint63.t;
}

let max_limit_of_staking_over_baking_millionth = Uint63.max_uint30

let maximum_edge_of_baking_over_staking_billionth =
  (* max is 1 (1_000_000_000 billionth) *)
  Uint63.one_billion

let default =
  {
    limit_of_staking_over_baking_millionth = Uint63.zero;
    edge_of_baking_over_staking_billionth = Uint63.one_billion;
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
    Uint63.(
      edge_of_baking_over_staking_billionth
      > maximum_edge_of_baking_over_staking_billionth)
  then Error ()
  else
    let limit_of_staking_over_baking_millionth =
      Uint63.min
        limit_of_staking_over_baking_millionth
        max_limit_of_staking_over_baking_millionth
    in
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
       (req "limit_of_staking_over_baking_millionth" Uint63.uint30_encoding)
       (req "edge_of_baking_over_staking_billionth" Uint63.uint30_encoding))

let make ~limit_of_staking_over_baking_millionth
    ~edge_of_baking_over_staking_billionth =
  match
    if Compare.Z.(limit_of_staking_over_baking_millionth < Z.zero) then Error ()
    else
      match Uint63.of_z edge_of_baking_over_staking_billionth with
      | None -> Error ()
      | Some edge_of_baking_over_staking_billionth ->
          let limit_of_staking_over_baking_millionth =
            Uint63.of_z limit_of_staking_over_baking_millionth
            |> Option.value ~default:Uint63.max_int
          in
          make
            ~limit_of_staking_over_baking_millionth
            ~edge_of_baking_over_staking_billionth
  with
  | Error () -> Result_syntax.tzfail Invalid_staking_parameters
  | Ok _ as ok -> ok
