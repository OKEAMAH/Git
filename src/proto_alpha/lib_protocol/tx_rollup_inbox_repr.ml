(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2022 Marigold <contact@marigold.dev>                        *)
(* Copyright (c) 2022 Nomadic Labs <contact@nomadic-labs.com>                *)
(* Copyright (c) 2022 Oxhead Alpha <info@oxhead-alpha.com>                   *)
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

type metadata = {
  cumulated_size : int;
  predecessor : Raw_level_repr.t option;
  successor : Raw_level_repr.t option;
}

let metadata_encoding =
  let open Data_encoding in
  conv
    (fun {cumulated_size; predecessor; successor} ->
      (cumulated_size, predecessor, successor))
    (fun (cumulated_size, predecessor, successor) ->
      {cumulated_size; predecessor; successor})
    (obj3
       (req "cumulated_size" int31)
       (req "predecessor" (option Raw_level_repr.encoding))
       (req "successor" (option Raw_level_repr.encoding)))

type content = Tx_rollup_message_repr.hash list

let content_encoding = Data_encoding.list Tx_rollup_message_repr.hash_encoding

type t = {content : content; metadata : metadata}

let pp fmt {content; metadata = {cumulated_size; _}} =
  Format.fprintf
    fmt
    "tx rollup inbox: %d messages using %d bytes"
    (List.length content)
    cumulated_size

let encoding =
  let open Data_encoding in
  conv
    (fun {content; metadata} -> (content, metadata))
    (fun (content, metadata) -> {content; metadata})
    (obj2
       (req "content" @@ content_encoding)
       (req "metadata" metadata_encoding))
