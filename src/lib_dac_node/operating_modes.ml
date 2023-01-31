(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2023 Trili Tech, <contact@trili.tech>                       *)
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

type ('coordinator, 'dac_member, 'observer, 'legacy) t =
  | Coordinator of 'coordinator
  | Dac_member of 'dac_member
  | Observer of 'observer
  | Legacy of 'legacy

let make_encoding ~coordinator_encoding ~dac_member_encoding ~observer_encoding
    ~legacy_encoding =
  Data_encoding.(
    union
      [
        case
          ~title:"coordinator"
          (Tag 0)
          coordinator_encoding
          (function Coordinator coordinator -> Some coordinator | _ -> None)
          (function coordinator -> Coordinator coordinator);
        case
          ~title:"dac_member"
          (Tag 1)
          dac_member_encoding
          (function Dac_member config -> Some config | _ -> None)
          (function config -> Dac_member config);
        case
          ~title:"observer"
          (Tag 2)
          observer_encoding
          (function Observer config -> Some config | _ -> None)
          (function config -> Observer config);
        case
          ~title:"legacy"
          (Tag 3)
          legacy_encoding
          (function Legacy config -> Some config | _ -> None)
          (function config -> Legacy config);
      ])
