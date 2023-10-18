(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2021 Nomadic Labs, <contact@nomadic-labs.com>               *)
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

external force_linking : unit -> unit = "%opaque"

let () =
  (* Zarith-related encodings *)
  let open Data_encoding in
  Registration.register
    ~pp:Z.pp_print
    (def "ground.Z" ~description:"Arbitrary precision integers" z) ;
  Registration.register
    ~pp:Z.pp_print
    (def "ground.N" ~description:"Arbitrary precision natural numbers" n)

let () =
  (* zero-length encodings *)
  let open Data_encoding in
  Registration.register (def "ground.unit" unit) ;
  Registration.register
    (def "ground.empty" ~description:"An empty (0-field) object or tuple" empty) ;
  Registration.register (def "ground.null" ~description:"A null value" null)

let () =
  (* integers of various sizes encodings *)
  let open Data_encoding in
  Registration.register
    (def "ground.uint8" ~description:"Unsigned 8 bit integers" uint8) ;
  Registration.register
    (def "ground.int8" ~description:"Signed 8 bit integers" int8) ;
  Registration.register
    (def "ground.uint16" ~description:"Unsigned 16 bit integers" uint16) ;
  Registration.register
    (def "ground.int16" ~description:"Signed 16 bit integers" int16) ;
  Registration.register
    (def "ground.int31" ~description:"Signed 31 bit integers" int31) ;
  Registration.register
    (def "ground.int32" ~description:"Signed 32 bit integers" int32) ;
  Registration.register
    (def "ground.int64" ~description:"Signed 64 bit integers" int64)

let () =
  (* string encodings *)
  let open Data_encoding in
  Registration.register (def "ground.string" string) ;
  Registration.register (def "ground.variable.string" Variable.string) ;
  Registration.register (def "ground.bytes" bytes) ;
  Registration.register (def "ground.variable.bytes" Variable.bytes)

let () =
  (* misc other ground encodings *)
  let open Data_encoding in
  Registration.register (def "ground.bool" ~description:"Boolean values" bool) ;
  Registration.register
    (def "ground.float" ~description:"Floating point numbers" float)

let () =
  (* Custom encodings registered for testing kaitai translation. *)
  let open Data_encoding in
  Registration.register
    (def "test.list_of_bool" ~description:"List of boolean values" (list bool)) ;
  Registration.register
    (def "test.list_of_uint8" ~description:"List of uint8 values" (list uint8)) ;
  Registration.register
    (def
       "test.fixed_list_of_bool"
       ~description:"Fixed sized list of boolean values"
       (Fixed.list 5 bool)) ;
  Registration.register
    (def
       "test.fixed_list_of_uint8"
       ~description:"Fixed sized list of uint8 values"
       (Fixed.list 5 uint8)) ;
  Registration.register
    (def
       "test.variable_list_of_bool"
       ~description:"Variable sized list of boolean values"
       (Variable.list bool)) ;
  Registration.register
    (def
       "test.variable_list_of_uint8"
       ~description:"Variable sized list of uint8 values"
       (Variable.list uint8)) ;
  Registration.register
    (def
       "test.nested_list_of_bool"
       ~description:"Nested list of boolean values"
       (list @@ list bool)) ;
  Registration.register
    (def
       "test.nested_list_of_uint8"
       ~description:"Nested list of uint8 values"
       (list @@ list uint8)) ;
  Registration.register
    (def
       "test.list_of_fixed_list_of_bool"
       ~description:"List of fixed sized list of boolean values"
       (list @@ Fixed.list 5 bool)) ;
  Registration.register
    (def
       "test.list_of_fixed_list_of_uint8"
       ~description:"List of fixed sized list of uint8 values"
       (list @@ Fixed.list 5 uint8)) ;
  Registration.register
    (def
       "test.fixed_list_of_fixed_list_of_bool"
       ~description:"Fixed sized list of fixed sized list of boolean values"
       (Fixed.list 5 @@ Fixed.list 100 bool)) ;
  Registration.register
    (def
       "test.fixed_list_of_fixed_list_of_uint8"
       ~description:"Fixed sized list of fixed sized list of uint8 values"
       (Fixed.list 100 @@ Fixed.list 5 uint8)) ;
  Registration.register
    (def
       "test.small_int_range"
       ~description:"Small int range"
       (ranged_int (-100) 100)) ;
  Registration.register
    (def
       "test.medium_int_range"
       ~description:"Medium int range"
       (ranged_int (-10000) 10000)) ;
  Registration.register
    (def
       "test.small_float_range"
       ~description:"Small float range"
       (ranged_float (-100.0) 100.0)) ;
  Registration.register
    (def
       "test.medium_float_range"
       ~description:"Medium float range"
       (ranged_float (-10000.0) 10000.0))

let () =
  Registration.register
    (def "ground.json" ~description:"JSON values" Data_encoding.json)
