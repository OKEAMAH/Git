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

module Client_parameters = struct
  type cached_value = Dal.t

  let namespace = Cache_repr.create_namespace "dal_parameters"

  let cache_index = 3

  let value_of_identifier ctxt _identifier = return (Raw_context.Dal.make ctxt)
end

module Cache_parameters =
  (val Cache_repr.register_exn (module Client_parameters))

let find_parameters ctxt =
  Cache_parameters.find ctxt "" >>= function
  | Error _ | Ok None ->
      (* This should not happen. But this value is rather easy to
         compute and we prefer to return it instead of just failing. *)
      Lwt.return (Raw_context.Dal.make ctxt)
  | Ok (Some parameters) -> Lwt.return parameters

module Client_srs = struct
  type cached_value = Dal.srs

  let namespace = Cache_repr.create_namespace "dal_srs"

  let cache_index = 4

  let value_of_identifier ctxt _identifier =
    find_parameters ctxt >>= fun parameters ->
    match Dal.load_srs parameters with
    | Ok srs -> return srs
    | Error _err ->
        invalid_arg
          "Client_srs.value_of_identifier: Unexpected error, unable to load \
           the srs"
end

module Cache_srs = (val Cache_repr.register_exn (module Client_srs))

let find_srs ctxt =
  Cache_srs.find ctxt "" >>=? function
  | None ->
      (* FIXME

         This can happen only if the srs was not initialised which
         cannot happen in practice. *)
      assert false
  | Some srs -> return srs
