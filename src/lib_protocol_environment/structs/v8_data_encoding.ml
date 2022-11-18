(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2022 Nomadic Labs. <contact@nomadic-labs.com>               *)
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

include V5_data_encoding

let bytestring : Tezos_stdlib.Bytestring.t encoding =
  conv
    (fun (s : Tezos_stdlib.Bytestring.t) ->
      Bytes.unsafe_of_string (s :> string))
    (fun b -> Tezos_stdlib.Bytestring.of_string (Bytes.unsafe_to_string b))
    bytes

module Variable = struct
  include Variable

  let bytestring : Tezos_stdlib.Bytestring.t encoding =
    conv
      (fun (s : Tezos_stdlib.Bytestring.t) ->
        Bytes.unsafe_of_string (s :> string))
      (fun b -> Tezos_stdlib.Bytestring.of_string (Bytes.unsafe_to_string b))
      Variable.bytes
end

module Fixed = struct
  include Fixed

  let bytestring size : Tezos_stdlib.Bytestring.t encoding =
    conv
      (fun (s : Tezos_stdlib.Bytestring.t) ->
        Bytes.unsafe_of_string (s :> string))
      (fun b -> Tezos_stdlib.Bytestring.of_string (Bytes.unsafe_to_string b))
      (Fixed.bytes size)
end
