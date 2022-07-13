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

type error += Srs_loading_failed

let () =
  register_error_kind
    `Permanent
    ~id:"dal_verifier.srs_loading_failed"
    ~title:"Srs loading failed"
    ~description:"The SRS value for the DAL could not be loaded"
    Data_encoding.unit
    (function Srs_loading_failed -> Some () | _ -> None)
    (fun () -> Srs_loading_failed)

module Cache_client = struct
  type 'a verifier = {
    verifier : (module Dal.VERIFIER with type srs = 'a);
    srs : 'a;
  }

  let dummy_key = "<dal_unused>"

  type cached_value = E : 'a verifier -> cached_value

  let namespace = Cache_repr.create_namespace "dal_verifier"

  let cache_index = 3

  let load_verifier (ctxt : Raw_context.t) : cached_value tzresult =
    let Constants_parametric_repr.{dal = {slot_size; number_of_shards; _}; _} =
      Raw_context.constants ctxt
    in
    let (module Constants : Dal.CONSTANTS) =
      (module struct
        let redundancy_factor = 16

        let segment_size = 4096 (* SCORU requirement *)

        let shards_amount = number_of_shards

        let slot_size = slot_size
      end)
    in
    let (module Verifier : Dal.VERIFIER) = (module Dal.Verifier (Constants)) in
    match Verifier.load_srs () with
    | Ok srs -> Ok (E {verifier = (module Verifier); srs})
    | Error (_err : shell_tztrace) ->
        Error (Error_monad.trace_of_error Srs_loading_failed)

  let value_of_identifier (ctxt : Raw_context.t) (s : string) =
    assert (Compare.String.(dummy_key = s)) ;
    Lwt.return (load_verifier ctxt)
end

module Cache = (val Cache_repr.register_exn (module Cache_client))

let initialisation ctxt =
  let Constants_parametric_repr.{dal = {feature_enable; _}; _} =
    Raw_context.constants ctxt
  in
  if not feature_enable then return ctxt
  else
    Cache.find ctxt Cache_client.dummy_key >>=? function
    | None ->
        Cache_client.load_verifier ctxt
        >>? (fun (value : Cache_client.cached_value) ->
              Cache.update ctxt Cache_client.dummy_key (Some (value, 1)))
        |> Lwt.return
    | Some (_ : Cache_client.cached_value) -> return ctxt
