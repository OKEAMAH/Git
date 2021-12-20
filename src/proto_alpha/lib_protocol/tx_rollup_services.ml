(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2021 Marigold <contact@marigold.dev>                        *)
(* Copyright (c) 2021 Nomadic Labs <contact@nomadic-labs.com>                *)
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

open Alpha_context

let level_from_offset ~offset ctxt =
  Level.from_raw_with_offset ctxt ~offset (Level.current ctxt).level
  >|? fun level -> level.level

let custom_root =
  (RPC_path.(open_root / "context" / "tx_rollup")
    : RPC_context.t RPC_path.context)

module S = struct
  let state =
    RPC_service.get_service
      ~description:"Access the state of a rollup."
      ~query:RPC_query.empty
      ~output:Tx_rollup_state.encoding
      RPC_path.(custom_root /: Tx_rollup.rpc_arg / "state")

  type level_query = {offset : int32}

  let level_query : level_query RPC_query.t =
    let open RPC_query in
    query (fun offset -> {offset})
    |+ field "offset" RPC_arg.int32 0l (fun t -> t.offset)
    |> seal

  let inbox =
    RPC_service.get_service
      ~description:"Get the inbox of a transaction rollup"
      ~query:level_query
      ~output:Tx_rollup_inbox.full_encoding
      RPC_path.(custom_root /: Tx_rollup.rpc_arg / "inbox")
end

type error += Positive_level_offset

let () =
  register_error_kind
    `Permanent
    ~id:"positive_level_offset"
    ~title:"The specified level offset is positive"
    ~description:"The specified level offset is positive"
    ~pp:(fun ppf () ->
      Format.fprintf ppf "The specified level offset should be negative.")
    Data_encoding.unit
    (function Positive_level_offset -> Some () | _ -> None)
    (fun () -> Positive_level_offset)

let register () =
  let open Services_registration in
  register1 ~chunked:false S.state (fun ctxt tx_rollup () () ->
      Tx_rollup.get_state_opt ctxt tx_rollup >|=? function
      | Some x -> x
      | None -> raise Not_found) ;
  register1 ~chunked:false S.inbox (fun ctxt tx_rollup q () ->
      fail_when Compare.Int32.(q.offset > 0l) Positive_level_offset
      >>=? fun () ->
      level_from_offset ~offset:q.offset ctxt >>?= fun level ->
      Tx_rollup.get_full_inbox_opt ctxt tx_rollup ~level >|=? function
      | Some x -> x
      | None -> raise Not_found)

let state ctxt block tx_rollup =
  RPC_context.make_call1 S.state ctxt block tx_rollup () ()

let inbox ctxt block ?(offset = 0l) tx_rollup =
  RPC_context.make_call1 S.inbox ctxt block tx_rollup {offset} ()
