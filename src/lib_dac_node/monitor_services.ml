(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2023 Marigold <contact@marigold.dev>                        *)
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

let streamed_page_encoding ((module P) : Dac_plugin.t) :
    Page_store.stream_page Data_encoding.t =
  Data_encoding.(
    conv
      (fun Page_store.{hash; content} -> (hash, content))
      (fun (hash, content) -> {hash; content})
      (obj2 (req "hash" P.encoding) (req "content" @@ bytes' Hex)))

module S = struct
  let root_hashes ((module P) : Dac_plugin.t) =
    Tezos_rpc.Service.get_service
      ~description:
        "Monitor a stream of root hashes that are produced by another dac node \
         responsible for the serialization of the dac payload (coordinator).  "
      ~query:Tezos_rpc.Query.empty
      ~output:P.encoding
      Tezos_rpc.Path.(open_root / "monitor" / "root_hashes")

  let saved_pages plugin =
    Tezos_rpc.Service.get_service
      ~description:"Monitor the pages saved by another dac node"
      ~query:Tezos_rpc.Query.empty
      ~output:(streamed_page_encoding plugin)
      Tezos_rpc.Path.(open_root / "monitor" / "pages")
end

let root_hashes dac_node_cctxt dac_plugin =
  Tezos_rpc.Context.make_streamed_call
    (S.root_hashes dac_plugin)
    dac_node_cctxt
    ()
    ()
    ()

let saved_pages dac_node_cctxt dac_plugin =
  Tezos_rpc.Context.make_streamed_call
    (S.saved_pages dac_plugin)
    dac_node_cctxt
    ()
    ()
    ()
