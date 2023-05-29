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

open Jingoo.Jg_types

val expand_update_var :
  vars:Global_variables.t ->
  agent:Remote_agent.t ->
  re:tvalue ->
  item:tvalue ->
  res:tvalue ->
  Global_variables.update ->
  Global_variables.update

val expand_remote_procedure :
  vars:Global_variables.t ->
  agent:Remote_agent.t ->
  re:tvalue ->
  item:tvalue ->
  string Remote_procedure.packed ->
  Uri.global_uri Remote_procedure.packed

val expand_job_body :
  vars:Global_variables.t ->
  agent:Remote_agent.t ->
  re:tvalue ->
  item:tvalue ->
  string Job.body ->
  Uri.global_uri Job.body

val expand_item :
  vars:Global_variables.t ->
  agent:Remote_agent.t ->
  re:tvalue ->
  Job.item ->
  tvalue Seq.t

val expand_agent :
  vars:Global_variables.t -> ?agent:Remote_agent.t -> string -> string
