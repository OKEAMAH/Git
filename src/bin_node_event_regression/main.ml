(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2023 Nomadic Labs, <contact@nomadic-labs.com>               *)
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

let event_as_string (Internal_event.Generic.Definition (section, name, e)) =
  let (module ED) = e in
  let section =
    Option.value ~default:""
    @@ Option.map
         (fun s -> Format.asprintf "%a" Internal_event.Section.pp s)
         section
  in
  Format.sprintf
    "%s,%s,%s,%S"
    name
    section
    (Internal_event.Level.to_string ED.level)
    ED.doc

let event_as_string (Internal_event.Generic.Definition (_, name, _) as d) =
  if String.starts_with ~prefix:"legacy_logging" name then None
  else Some (event_as_string d)

let () =
  let _cmds = Octez_node_commands.Node_commands.all in
  let definitions = Internal_event.All_definitions.get () in
  List.filter_map event_as_string definitions
  |> String.concat "\n" |> Format.printf "%s@."
