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

(**
   Handling of YAML configuration file used by the kernel installer.

   A configuration has the form:
   ```
   instructions:
     - set:
         value: <hexadecimal value>
         to: <string>
     ...
   ```
*)

type error +=
  | Installer_config_yaml_error of string
  | Installer_config_invalid
  | Installer_config_invalid_instruction of int

(* Instructions of the installer configuration. *)
type instr = Set of {value : string; to_ : string}

(* A configuration is a set of instructions. *)
type t = instr list

val pp : Format.formatter -> instr list -> unit

val instr_encoding : instr Data_encoding.t

val encoding : t Data_encoding.t

(** [parse_yaml content] parses [content] as a YAML representing the
    configuration of the kernel installer, and returns the corresponding set of
    instructions. *)
val parse_yaml : string -> t tzresult

(** [generate_yaml instrs] generates the YAML representation of [instrs]. *)
val generate_yaml : t -> Yaml.yaml tzresult

(** [emit_yaml instrs] generates the YAML representation of [instrs] in textual
    format. *)
val emit_yaml : t -> string tzresult
