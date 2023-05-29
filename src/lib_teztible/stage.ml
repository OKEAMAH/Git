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

type t = {
  name : string;
  with_agents : string list;
  run_agents : Execution_params.mode;
  run_jobs : Execution_params.mode;
  jobs : string Job.t list;
}

let encoding =
  Data_encoding.(
    conv
      (fun {name; with_agents; run_agents; run_jobs; jobs} ->
        (name, with_agents, run_agents, run_jobs, jobs))
      (fun (name, with_agents, run_agents, run_jobs, jobs) ->
        {name; with_agents; run_agents; run_jobs; jobs})
      (obj5
         (req "name" string)
         (dft
            "with_agents"
            (union
               [
                 case
                   ~title:"string"
                   (Tag 0)
                   string
                   (function [x] -> Some x | _ -> None)
                   (fun x -> [x]);
                 case
                   ~title:"list"
                   (Tag 1)
                   (list string)
                   (fun x -> Some x)
                   (fun x -> x);
               ])
            [".*"])
         (dft "run_agents" Execution_params.mode_encoding Concurrent)
         (dft "run_jobs" Execution_params.mode_encoding Sequential)
         (req "jobs" (list Job.encoding))))
