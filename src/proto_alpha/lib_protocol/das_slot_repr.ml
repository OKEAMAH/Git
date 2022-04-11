(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2022 Nomadic Labs <contact@nomadic-labs.com>                *)
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

module Header = struct
  (* DAS/FIXME *)
  type t = int

  let encoding = Data_encoding.int31

  let pp = Format.pp_print_int
end

type index = int

type t = {level : Raw_level_repr.t; slot : index; header : Header.t}

let encoding =
  let open Data_encoding in
  conv
    (fun {level; slot; header} -> (level, slot, header))
    (fun (level, slot, header) -> {level; slot; header})
    (obj3
       (req "level" Raw_level_repr.encoding)
       (req "slot" Data_encoding.int8)
       (req "header" Header.encoding))

let pp fmt {level; slot; header} =
  Format.fprintf
    fmt
    "level: %a slot: %a header: %a"
    Raw_level_repr.pp
    level
    Format.pp_print_int
    slot
    Header.pp
    header

let index {slot; _} = slot
