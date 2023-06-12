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
type raw_data = {blake2B : Raw_level_repr.t}

type t = {
  raw_data : raw_data;
  partial_raw_data : raw_data;
  metadata : Raw_level_repr.t;
  dal_page : Raw_level_repr.t;
}

let encoding : t Data_encoding.t =
  let open Data_encoding in
  let raw_data_encoding =
    conv
      (fun t -> t.blake2B)
      (fun blake2B -> {blake2B})
      (obj1 (req "Blake2B" Raw_level_repr.encoding))
  in
  conv
    (fun t -> (t.raw_data, t.partial_raw_data, t.metadata, t.dal_page))
    (fun (raw_data, partial_raw_data, metadata, dal_page) ->
      {raw_data; partial_raw_data; metadata; dal_page})
    (obj4
       (req "raw_data" raw_data_encoding)
       (req "partial_raw_data" raw_data_encoding)
       (req "metadata" Raw_level_repr.encoding)
       (req "dal_page" Raw_level_repr.encoding))
